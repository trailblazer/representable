require "test_helper"

class DefaultTest < MiniTest::Spec
  Song = Struct.new(:id, :title, :album)

  representer! do
    property :id
    property :title, default: "Huber Breeze" #->(options) { options[:default] }
    property :album, default: ->(represented:, **) { represented.album || "Spring" }
  end

  describe "#from_hash" do
    let(:new_song) { Song.new.extend(representer) }
    let(:old_song) { Song.new(1, nil, "Atumn").extend(representer) }

    it { _(old_song.from_hash({})).must_equal Song.new(1, "Huber Breeze", "Atumn") }
    it { _(new_song.from_hash({})).must_equal Song.new(nil, "Huber Breeze", "Spring") }
    # default doesn't apply when empty string.
    it { _(old_song.from_hash({"title"=>"", "album"=>""})).must_equal Song.new(1, "", "") }
    it { _(new_song.from_hash({"title"=>"", "album"=>""})).must_equal Song.new(nil, "", "") }
    it { _(old_song.from_hash({"title"=>nil, "album"=>nil})).must_equal Song.new(1, nil, nil) }
    it { _(new_song.from_hash({"title"=>nil, "album"=>nil})).must_equal Song.new(nil, nil, nil) }
    it { _(old_song.from_hash({"title"=>"Blindfold", "album"=>"Lil"})).must_equal Song.new(1, "Blindfold", "Lil") }
    it { _(new_song.from_hash({"title"=>"Blindfold", "album"=>"Lil"})).must_equal Song.new(nil, "Blindfold", "Lil") }
  end

  describe "#to_json" do
    it "uses :default when not available from object" do
      _(Song.new.extend(representer).to_hash).must_equal({"title"=>"Huber Breeze", "album"=>"Spring"})
    end

    it "uses value from represented object when present" do
      _(Song.new(nil, "After The War", "1964").extend(representer).to_hash).must_equal({"title"=>"After The War","album"=>"1964"})
    end

    it "uses value from represented object when emtpy string" do
      _(Song.new(nil, "", "").extend(representer).to_hash).must_equal({"title"=>"", "album"=>""})
    end
  end
end