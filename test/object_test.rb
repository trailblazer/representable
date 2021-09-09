require "test_helper"
require "representable/object"
require "representable/decorator"

class ObjectTest < MiniTest::Spec
  Song  = Struct.new(:title, :album)
  Album = Struct.new(:name, :songs)

  representer!(module: Representable::Object) do
    property :title

    property :album, instance: lambda { |options| options[:fragment].name.upcase!; options[:fragment] } do
      property :name

      collection :songs, instance: lambda { |options| options[:fragment].title.upcase!; options[:fragment] } do
        property :title
      end
    end
    # TODO: collection
  end

  let(:source) { Song.new("The King Is Dead", Album.new("Ruiner", [Song.new("In Vino Veritas II")])) }
  let(:target) { Song.new }

  describe ".from_object" do
    describe "when using object with nested records as source" do
      it "copies nested information to target object" do
        representer.prepare(target).from_object(source)

        _(target.title).must_equal("The King Is Dead")
        _(target.album.name).must_equal("RUINER")
        _(target.album.songs[0].title).must_equal("IN VINO VERITAS II")
      end
    end

    describe "when nested object is nil" do
      let(:target) do
        representer.prepare(Song.new("The King Is Dead")).from_object(Song.new)
      end

      it "overrides value that was not nil" do
        _(target.title).must_be_nil
      end
    end
  end

  describe "#to_object" do
    representer!(module: Representable::Object) do
      property :title

      property :album, render_filter: lambda { |input, options|input.name = "Live";input } do
        property :name

        collection :songs, render_filter: lambda { |input, options|input[0].title = 1;input } do
          property :title
        end
      end
    end

    it "transforms the object using representer" do
      representer.prepare(source).to_object

      _(source.album.name).must_equal("Live")
      _(source.album.songs[0].title).must_equal(1)
    end

    describe "when used as decorator" do
      representer!(name: :decorator ,module: Representable::Object, decorator: true) do
        property :name, getter: ->(represented:, **) {
          represented.name = "#{represented.name} is the best team of America"
        }
      end

      let(:target) { Album.new("Atletico Nacional") }

      it "transforms object" do
        decorator.prepare(target).to_object

        _(target.name).must_equal("Atletico Nacional is the best team of America")
      end
    end
  end
end
