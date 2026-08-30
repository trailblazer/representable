require "test_helper"
require "representable/object"

class ObjectTest < Minitest::Spec
  Song  = Struct.new(:title, :album)
  Album = Struct.new(:name, :songs)

  representer!(module: Representable::Object) do
    property :title

    property :album, instance: ->(options) { options[:fragment].name.upcase!; options[:fragment] } do
      property :name

      collection :songs, instance: ->(options) { options[:fragment].title.upcase!; options[:fragment] } do
        property :title
      end
    end
    # TODO: collection
  end

  let(:source) { Song.new("The King Is Dead", Album.new("Ruiner", [Song.new("In Vino Veritas II")])) }
  let(:target) { Song.new }

  it do
    representer.prepare(target).from_object(source)

    assert_equal "The King Is Dead", target.title
    assert_equal "RUINER", target.album.name
    assert_equal "IN VINO VERITAS II", target.album.songs[0].title
  end

  # ignore nested object when nil
  it do
    representer.prepare(Song.new("The King Is Dead")).from_object(Song.new)

    assert_nil target.title # scalar property gets overridden when nil.
    assert_nil target.album # nested property stays nil.
  end

  # to_object
  describe "#to_object" do
    representer!(module: Representable::Object) do
      property :title

      property :album, render_filter: ->(input, _options) { input.name = "Live"; input } do
        property :name

        collection :songs, render_filter: ->(input, _options) { input[0].title = 1; input } do
          property :title
        end
      end
    end

    it do
      representer.prepare(source).to_object
      _(source.album.name).must_equal "Live"
      _(source.album.songs[0].title).must_equal 1
    end
  end
end
