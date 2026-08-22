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
    cpp = process_post(post)

    roll = ::Rollmaster::Roll.find_by(post_id: post.id)

    expect(roll).not_to be_nil
    expect(roll.post_id).to eq(post.id)
    expect(roll.raw).to eq("2d6")
    expect(post.custom_fields[::Rollmaster::POST_CUSTOM_FIELD]).to be(true)
    expect(cpp.html).to include("data-roll-id=\"#{roll.id}\"")
  end

  it "renders markup-like dice comments as text" do
    comment = '<img src=x onerror="alert(1)">'
    post = Fabricate(:post, raw: "[roll]1d6 // #{comment}[/roll]")
    post.save

    cpp = process_post(post)
    document = Nokogiri::HTML5.fragment(cpp.html)

    expect(document.css("img")).to be_empty
    expect(document.text).to include(comment)
  end

  it "handles multiple [roll] BBCode in a single post" do
    post = Fabricate(:post, raw: <<~MD)
      Here are some rolls:
      [roll]1d20[/roll]
      [roll]3d8+2[/roll]
      [roll]4d6kh3[/roll]
    MD
    post.save
    cpp = process_post(post)

    rolls = ::Rollmaster::Roll.where(post_id: post.id).to_a

    expect(rolls.size).to eq(3)
    expect(rolls.map(&:raw)).to contain_exactly("1d20", "3d8+2", "4d6kh3")
    rolls.each { |roll| expect(cpp.html).to include("data-roll-id=\"#{roll.id}\"") }
  end

  it "preserves duplicate notation roll order across edits" do
    post = Fabricate(:post, raw: '[roll="First"]1d6[/roll]' + "\n" + '[roll="Second"]1d6[/roll]')
    process_post(post)
    original_roll_ids =
      ::Rollmaster::Roll.where(post_id: post.id).order(:created_at, :id).pluck(:id)

    post.raw = '[roll="Updated first"]1d6[/roll]' + "\n" + '[roll="Updated second"]1d6[/roll]'
    post.save
    cpp = process_post(post)
    roll_ids =
      Nokogiri::HTML5
        .fragment(cpp.html)
        .css("blockquote.bb-rollmaster-result")
        .map { |element| element["data-roll-id"].to_i }

    expect(roll_ids).to eq(original_roll_ids)
  end

  it "reuses existing rolls when a post is edited" do
    post = Fabricate(:post, raw: <<~MD)
      Initial roll: [roll]1d6[/roll]
    MD
    post.save
    cpp = process_post(post)

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
    cpp = process_post(post)

    rolls = ::Rollmaster::Roll.where(post_id: post.id).to_a
    expect(rolls.size).to eq(2)
    expect(rolls.map(&:raw)).to contain_exactly("1d6", "1d4+1")
    expect(initial_roll.id).in?(rolls.map(&:id))
    rolls.each { |roll| expect(cpp.html).to include("data-roll-id=\"#{roll.id}\"") }
  end

  it "preserves the result when editing a roll description" do
    user = Fabricate(:user)
    post = Fabricate(:post, user: user, raw: '[roll="Initial description"]{4d6+2d8-3d30}d3[/roll]')
    process_post(post)
    initial_roll = ::Rollmaster::Roll.find_by!(post_id: post.id)
    initial_result = initial_roll.result

    SiteSetting.editing_grace_period = 0
    PostRevisor.new(post).revise!(
      user,
      { raw: '[roll="Updated description"]{4d6+2d8-3d30}d3[/roll]', edit_reason: "update roll" },
    )

    rolls = ::Rollmaster::Roll.where(post_id: post.id)

    expect(rolls).to contain_exactly(initial_roll)
    expect(initial_roll.reload).to have_attributes(
      desc: "Updated description",
      result: initial_result,
    )
  end

  it "reuses a roll when a later edit restores its formatted notation" do
    post = Fabricate(:post, raw: <<~MD)
      Initial roll: [roll]1d6[/roll]
    MD
    post.save

    process_post(post)

    initial_roll = ::Rollmaster::Roll.find_by!(post_id: post.id, raw: "1d6")

    post.raw = <<~MD
      Updated roll: [roll]1d8[/roll]
    MD
    post.save

    process_post(post)

    post.raw = <<~MD
      Back to the original notation: [roll]1d6[/roll]
    MD
    post.save

    restored_cpp = process_post(post)

    rolls = ::Rollmaster::Roll.where(post_id: post.id).order(:created_at, :id)

    expect(rolls.map(&:raw)).to eq(%w[1d6 1d8])
    expect(restored_cpp.html).to include("data-roll-id=\"#{initial_roll.id}\"")
  end

  it "renders an error and saves no roll when a notation parses but cannot be rolled" do
    post = Fabricate(:post, raw: "[roll]1d1r[/roll]")
    post.save

    cpp = process_post(post)
    roll_element = Nokogiri::HTML5.fragment(cpp.html).at_css("blockquote.bb-rollmaster-result")

    expect(::Rollmaster::Roll.where(post_id: post.id)).to be_empty
    expect(roll_element["data-roll-id"]).to be_nil
    expect(roll_element["class"]).to include("--error")
    expect(roll_element.at_css(".bb-rollmaster-results").text).to include("re-roll")
    expect(post.reload.has_rolls?).to be(false)
  end

  it "keeps has_rolls? set once a roll has been made, even if a later edit only errors" do
    post = Fabricate(:post, raw: "[roll]2d6[/roll]")
    post.save
    process_post(post)
    original_roll = ::Rollmaster::Roll.find_by!(post_id: post.id)

    post.raw = "[roll]1d1r[/roll]"
    post.save
    process_post(post)

    expect(::Rollmaster::Roll.where(post_id: post.id)).to contain_exactly(original_roll)
    expect(post.reload.has_rolls?).to be(true)
  end

  it "renders a generic error and saves no roll when the engine fails while rolling" do
    allow(::Rollmaster::DiceEngine).to receive(:roll).and_raise(
      MiniRacer::ScriptTerminatedError,
      "script terminated",
    )

    post = Fabricate(:post, raw: "[roll]2d6[/roll]")
    post.save

    cpp = process_post(post)
    roll_element = Nokogiri::HTML5.fragment(cpp.html).at_css("blockquote.bb-rollmaster-result")

    expect(::Rollmaster::Roll.where(post_id: post.id)).to be_empty
    expect(roll_element["class"]).to include("--error")
    expect(roll_element.at_css(".bb-rollmaster-results").text).to eq(
      I18n.t("rollmaster.engine_error"),
    )
    expect(post.reload.has_rolls?).to be(false)
  end

  it "renders a generic error and saves no roll when the engine fails while formatting" do
    allow(::Rollmaster::DiceEngine).to receive(:format_notation).and_raise(
      MiniRacer::ScriptTerminatedError,
      "script terminated",
    )

    post = Fabricate(:post, raw: "[roll]2d6[/roll]")
    post.save

    cpp = process_post(post)
    roll_element = Nokogiri::HTML5.fragment(cpp.html).at_css("blockquote.bb-rollmaster-result")

    expect(::Rollmaster::Roll.where(post_id: post.id)).to be_empty
    expect(roll_element["class"]).to include("--error")
    expect(roll_element.at_css(".bb-rollmaster-results").text).to eq(
      I18n.t("rollmaster.engine_error"),
    )
  end

  it "does not re-roll a notation that was matched to an existing roll" do
    post = Fabricate(:post, raw: "[roll]2d6[/roll]")
    post.save
    process_post(post)

    allow(::Rollmaster::DiceEngine).to receive(:format_notation).and_call_original
    allow(::Rollmaster::DiceEngine).to receive(:roll)

    post.raw = '[roll="now with a description"]2d6[/roll]'
    post.save
    process_post(post)

    expect(::Rollmaster::DiceEngine).to have_received(:format_notation).once
    expect(::Rollmaster::DiceEngine).not_to have_received(:roll)
  end

  it "keeps rolling the remaining rolls when one of them fails" do
    post = Fabricate(:post, raw: "[roll]1d1r[/roll]\n[roll]2d6[/roll]")
    post.save

    cpp = process_post(post)
    elements = Nokogiri::HTML5.fragment(cpp.html).css("blockquote.bb-rollmaster-result")
    saved_roll = ::Rollmaster::Roll.find_by!(post_id: post.id)

    expect(saved_roll.raw).to eq("2d6")
    expect(elements.first["class"]).to include("--error")
    expect(elements.last["data-roll-id"]).to eq(saved_roll.id.to_s)
  end

  def process_post(post)
    cpp = CookedPostProcessor.new(post)
    cpp.post_process
    post.update_column(:cooked, cpp.html)
    cpp
  end
end
