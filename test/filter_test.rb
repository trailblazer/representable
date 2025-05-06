require "test_helper"

class FilterPipelineTest < MiniTest::Spec
  let(:block1) { ->(input, _options) { "1: #{input}" } }
  let(:block2) { ->(input, _options) { "2: #{input}" } }

  subject { Representable::Pipeline[block1, block2] }

  it { _(subject.call("Horowitz", {})).must_equal "2: 1: Horowitz" }
end

class FilterTest < MiniTest::Spec
  representer! do
    property :title

    property :track,
             :parse_filter  => ->(input, options) { "#{input.downcase},#{options[:doc]}" },
             :render_filter => ->(val, options) { "#{val.upcase},#{options[:doc]},#{options[:options][:user_options]}" }
  end

  # gets doc and options.
  it {
    input = {"title" => "VULCAN EARS", "track" => "Nine"}
    song = OpenStruct.new.extend(representer).from_hash(input)
    _(song.title).must_equal "VULCAN EARS"
    _(song.track).must_equal "nine,#{input}"
  }

  it {
    val = {"title" => "vulcan ears"}
    _(
      OpenStruct.new(
        "title" => "vulcan ears",
        "track" => "Nine"
      ).extend(representer).to_hash
    ).must_equal({
                   "title" => "vulcan ears",
                   "track" => "NINE,#{val},{}"
                 })
  }

  describe "#parse_filter" do
    representer! do
      property :track,
               :parse_filter  => [
                 ->(input, _options) { "#{input}-1" },
                 ->(input, _options) { "#{input}-2" }
               ],
               :render_filter => [
                 ->(val, _options) { "#{val}-1" },
                 ->(val, _options) { "#{val}-2" }
               ]
    end

    # order matters.
    it { _(OpenStruct.new.extend(representer).from_hash("track" => "Nine").track).must_equal "Nine-1-2" }
    it { _(OpenStruct.new("track" => "Nine").extend(representer).to_hash).must_equal({"track"=>"Nine-1-2"}) }
  end
end

# class RenderFilterTest < MiniTest::Spec
#   representer! do
#     property :track, :render_filter => [lambda { |val, options| "#{val}-1" } ]
#     property :track, :render_filter => [lambda { |val, options| "#{val}-2" } ], :inherit => true
#   end

#   it { OpenStruct.new("track" => "Nine").extend(representer).to_hash.must_equal({"track"=>"Nine-1-2"}) }
# end
