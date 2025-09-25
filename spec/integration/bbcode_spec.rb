# frozen_string_literal: true

RSpec.describe "Rollmaster BBCode integration", type: :integration do
  before do
    enable_current_plugin
    Jobs.run_immediately!
  end

  it "processes [roll] BBCode and creates a Roll record" do
    post = Fabricate(:post, raw: <<~MD)
      [roll]2d6[/roll]
    MD
    post.save
    cpp = CookedPostProcessor.new(post)
    cpp.post_process

    roll = ::Rollmaster::Roll.find_by(post_id: post.id)

    expect(roll).not_to be_nil
    expect(roll.post_id).to eq(post.id)
    expect(roll.raw).to eq("2d6")
    expect(post.custom_fields[::Rollmaster::POST_CUSTOM_FIELD]).to be(true)
    expect(cpp.html).to include("data-roll-id=\"#{roll.id}\"")
  end

  it "handles multiple [roll] BBCode in a single post" do
    post = Fabricate(:post, raw: <<~MD)
      Here are some rolls:
      [roll]1d20[/roll]
      [roll]3d8+2[/roll]
      [roll]4d6kh3[/roll]
    MD
    post.save
    cpp = CookedPostProcessor.new(post)
    cpp.post_process

    rolls = ::Rollmaster::Roll.where(post_id: post.id).to_a

    expect(rolls.size).to eq(3)
    expect(rolls.map(&:raw)).to contain_exactly("1d20", "3d8+2", "4d6kh3")
    rolls.each { |roll| expect(cpp.html).to include("data-roll-id=\"#{roll.id}\"") }
  end

  it "reuses existing rolls when a post is edited" do
    post = Fabricate(:post, raw: <<~MD)
      Initial roll: [roll]1d6[/roll]
    MD
    post.save
    cpp = CookedPostProcessor.new(post)
    cpp.post_process

    initial_roll = ::Rollmaster::Roll.find_by(post_id: post.id)
    expect(initial_roll).not_to be_nil
    expect(initial_roll.raw).to eq("1d6")

    # Edit the post to change the roll
    post.raw = <<~MD
      Updated rolls:
      [roll]1d6[/roll]
      [roll]1d4+1[/roll]
    MD
    post.save
    cpp = CookedPostProcessor.new(post)
    cpp.post_process

    rolls = ::Rollmaster::Roll.where(post_id: post.id).to_a
    expect(rolls.size).to eq(2)
    expect(rolls.map(&:raw)).to contain_exactly("1d6", "1d4+1")
    expect(initial_roll.id).in?(rolls.map(&:id))
    rolls.each { |roll| expect(cpp.html).to include("data-roll-id=\"#{roll.id}\"") }
  end
end
