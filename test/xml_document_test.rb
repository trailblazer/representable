require "test_helper"

# Nested representers must build their nodes in the parent's document. A node
# built in a separate document gets copied when it is appended, and the
# NodeSet that collected it is left pointing at the freed original (#302).
class XmlDocumentTest < Minitest::Spec
  Order = Struct.new(:items)
  Item = Struct.new(:id)

  # Records the document each node was built in, before the node is appended
  # anywhere: Nokogiri re-points a copied node at its copy's document.
  class ItemRepresenter < Representable::Decorator
    include Representable::XML
    self.representation_wrap = :item

    property :id, attribute: true

    def to_node(options = {})
      super.tap { options[:user_options][:documents] << _1.document }
    end
  end

  module ItemsRepresenter
    include Representable::XML::Collection
    self.representation_wrap = :items

    items decorator: ItemRepresenter
  end

  let(:documents) { [] }
  let(:user_options) { { documents: documents } }
  let(:order) { Order.new([Item.new(1), Item.new(2)]) }

  describe "collection" do
    let(:representer) do
      Class.new(Representable::Decorator) do
        include Representable::XML
        self.representation_wrap = :order

        collection :items, as: :item, decorator: ItemRepresenter
      end
    end

    it "builds the items in the parent's document" do
      node = representer.new(order).to_node(user_options: user_options)

      assert_equal 2, documents.size
      documents.each { assert_same node.document, _1 }
    end
  end

  describe "property" do
    let(:representer) do
      Class.new(Representable::Decorator) do
        include Representable::XML
        self.representation_wrap = :order

        property :first_item, as: :item, decorator: ItemRepresenter,
          getter: ->(*) { items.first }
      end
    end

    it "builds the item in the parent's document" do
      node = representer.new(order).to_node(user_options: user_options)

      assert_equal 1, documents.size
      assert_same node.document, documents.first
    end
  end

  describe "lonely collection" do
    let(:representer) do
      Class.new(Representable::Decorator) do
        include Representable::XML
        include ItemsRepresenter
      end
    end

    it "builds the items in the collection's document" do
      node = representer.new(order.items).to_node(user_options: user_options)

      assert_equal 2, documents.size
      documents.each { assert_same node.document, _1 }
    end
  end
end
