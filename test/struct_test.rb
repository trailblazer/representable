require "test_helper"
require "representable/struct"

class StructPublicMethodsTest < Minitest::Spec
  Song  = Struct.new(:title, :album)
  Album = Struct.new(:id, :name, :songs, :free_concert_ticket_promo_code)
  class AlbumRepresenter < Representable::Decorator
    include Representable::Struct
    property :id
    property :name, getter: ->(*) { name.lstrip.strip }
    property :cover_png, getter: ->(options:, **) { options[:cover_png] }
    collection :songs do
      property :title, getter: ->(*) { title.upcase }
      property :album, getter: ->(*) { album.upcase }
    end
  end

  #---
  # to_struct
  let(:album) { Album.new(1, "  Rancid   ", [Song.new("In Vino Veritas II", "Rancid"), Song.new("The King Is Dead", "Rancid")], "S3KR3TK0D3") }
  let(:cover_png) { "example.com/cover.png" }
  it do
    represented = AlbumRepresenter.new(album).to_struct(cover_png: cover_png)
    assert_equal album.id, represented.id
    refute_equal album.name, represented.name
    assert_equal album.name.lstrip.strip, represented.name
    refute_equal album.songs[0].title, represented.songs[0].title
    assert_equal album.songs[0].title.upcase, represented.songs[0].title

    assert_respond_to album, :free_concert_ticket_promo_code
    refute_respond_to represented, :free_concert_ticket_promo_code

    assert_equal cover_png, represented.cover_png
  end

  it do
    represented = AlbumRepresenter.new(album).to_struct(cover_png: cover_png)
    assert_equal album.id, represented.id
    refute_equal album.name, represented.name
    assert_equal album.name.lstrip.strip, represented.name
    refute_equal album.songs[0].title, represented.songs[0].title
    assert_equal album.songs[0].title.upcase, represented.songs[0].title

    assert_respond_to album, :free_concert_ticket_promo_code
    refute_respond_to represented, :free_concert_ticket_promo_code

    assert_equal cover_png, represented.cover_png
  end

  let(:albums) do  [
    Album.new(1, "Rancid", [Song.new("In Vino Veritas II", "Rancid"), Song.new("The King Is Dead", "Rancid")], "S3KR3TK0D3"),
    Album.new(2, "Punk powerhouse", [Song.new("Hard Outside The Box", "Punk powerhous"), Song.new("Wonderful Noise", "Punk powerhous")], "S3KR3TK0D3"),
    Album.new(3, "Into the Beyond", [Song.new("Rhythm of the night", "Into the Beyond"), Song.new("I'm blue", "Into the Beyond")], "S3KR3TK0D3"),
  ]
  end

  it do
    represented = AlbumRepresenter.for_collection.new(albums).to_struct(cover_png: cover_png)
    assert_equal albums.size, represented.size
    assert_respond_to albums[0], :free_concert_ticket_promo_code
    refute_respond_to represented[0], :free_concert_ticket_promo_code
    assert_equal cover_png, represented[0].cover_png
    assert_equal represented[1].class.object_id, represented[0].class.object_id
  end

  let(:wrapper) { "cool_album" }
  let(:second_wrapper) { "magnificent_album" }
  it do
    represented_array = AlbumRepresenter.for_collection.new(albums).to_struct(wrap: wrapper)
    represented_object = AlbumRepresenter.new(album).to_struct(wrap: second_wrapper)

    assert_respond_to represented_array, wrapper

    assert_respond_to represented_array.send(wrapper)[0], wrapper
    first_song_title_represented = represented_array.send(wrapper)[0].send(wrapper).songs[0].title
    first_song_title_original = albums[0].songs[0].title
    assert_equal first_song_title_original.upcase, first_song_title_represented

    assert_equal represented_array.send(wrapper)[0].class.object_id, represented_array.send(wrapper)[1].class.object_id # wrapper struct class is the same for collection
    refute_equal represented_array.send(wrapper)[0].class.object_id, represented_object.class.object_id   # wrapper structs classes are different for different wrappers
  end
end
