require "test_helper"

class DefaultTest < MiniTest::Spec
  TIMESTAMP = Time.now

  Composer = Struct.new(:id, :name, :keywords)
  Song = Struct.new(:id, :title, :album, :composers, :created_at, :created_by)

  representer! do
    property :id
    property :title, default: "Huber Breeze" #->(options) { options[:default] }
    property :album, default: ->(represented:, **) { represented.album || "Spring" }
    collection :composers, instance: ->(*) { Composer.new } do
      property :id
      property :name, default: "Unknown"
      property :keywords, default: ->(represented:, **) { [represented.name.downcase] }
    end
    nested :metadata do
      property :created_by, default: :default_creator, exec_context: :decorator
      property :created_at, default: ->(*) { TIMESTAMP }

      def default_creator(*)
        represented.composers&.first ? represented.composers.first.id : nil
      end

      def created_by
        represented.created_by
      end

      def created_by=(value)
        represented.created_by = value
      end
    end
  end

  describe "#from_hash" do
    let(:new_song) { Song.new.extend(representer) }
    let(:old_song) { Song.new(1, nil, "Atumn",[Composer.new(1, "Jerry")]).extend(representer) }

    it { _(old_song.from_hash({})).must_equal Song.new(1, "Huber Breeze", "Atumn",[Composer.new(1, "Jerry")]) }
    it { _(new_song.from_hash({})).must_equal Song.new(nil, "Huber Breeze", "Spring") }

    it { _(old_song.from_hash({"title"=>"Blindfold", "album"=>"Lil"})).must_equal Song.new(1, "Blindfold", "Lil",[Composer.new(1, "Jerry")]) }
    it { _(new_song.from_hash({"title"=>"Blindfold", "album"=>"Lil"})).must_equal Song.new(nil, "Blindfold", "Lil") }

    # default doesn't apply when empty string.
    it { _(old_song.from_hash({"title"=>"", "album"=>""})).must_equal Song.new(1, "", "",[Composer.new(1, "Jerry")]) }
    it { _(new_song.from_hash({"title"=>"", "album"=>""})).must_equal Song.new(nil, "", "") }
    it { _(old_song.from_hash({"title"=>nil, "album"=>nil})).must_equal Song.new(1, nil, nil,[Composer.new(1, "Jerry")]) }
    it { _(new_song.from_hash({"title"=>nil, "album"=>nil})).must_equal Song.new(nil, nil, nil) }

    # defaults within empty collections and nested
    it { _(old_song.from_hash({"composers"=>[],"metadata"=>{}})).must_equal Song.new(1, "Huber Breeze", "Atumn", [], TIMESTAMP, nil) }
    it { _(new_song.from_hash({"composers"=>[],"metadata"=>{}})).must_equal Song.new(nil, "Huber Breeze", "Spring", [], TIMESTAMP, nil) }
    it { _(old_song.from_hash({"composers"=>[{}],"metadata"=>{"created_at"=>"", "created_by"=>""}})).must_equal Song.new(1, "Huber Breeze", "Atumn", [Composer.new(nil, "Unknown", ["unknown"])], "", "") }
    it { _(new_song.from_hash({"composers"=>[{}],"metadata"=>{"created_at"=>"", "created_by"=>""}})).must_equal Song.new(nil, "Huber Breeze", "Spring", [Composer.new(nil, "Unknown", ["unknown"])], "", "") }

    # defaults within filled collections and nested
    it { _(new_song.from_hash({"composers"=>[{"id"=>1,"name"=>"Tom"}],"metadata"=>{"created_at"=>2022}})).must_equal Song.new(nil, "Huber Breeze", "Spring", [Composer.new(1, "Tom", ["tom"])], 2022, 1) }
  end

  describe "#to_json" do
    it "uses :default when not available from object" do
      _(Song.new.extend(representer).to_hash).must_equal({"title"=>"Huber Breeze", "album"=>"Spring", "metadata"=>{"created_at"=>TIMESTAMP}})
    end

    it "uses value from represented object when present" do
      _(Song.new(nil, "After The War", "1964").extend(representer).to_hash).must_equal({"title"=>"After The War","album"=>"1964","metadata"=>{"created_at"=>TIMESTAMP}})
    end

    it "uses value from represented object when emtpy string" do
      _(Song.new(nil, "", "").extend(representer).to_hash).must_equal({"title"=>"", "album"=>"","metadata"=>{"created_at"=>TIMESTAMP}})
    end
  end
end
