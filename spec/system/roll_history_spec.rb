# frozen_string_literal: true

RSpec.describe "Roll history", type: :system do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:topic)
  fab!(:post) { Fabricate(:post, topic: topic, user: user, raw: "Opening roll: [roll]1d6[/roll]") }

  let(:roll_history_modal) { PageObjects::Modals::RollHistory.new }
  let(:topic_page) { PageObjects::Pages::RollmasterTopic.new }

  before do
    enable_current_plugin
    SiteSetting.rollmaster_enabled = true

    process_rolls(post)
    process_rolls(post, "Changed roll: [roll]1d8[/roll]")
    process_rolls(post, "Back again: [roll]1d6[/roll]")

    sign_in(user)
  end

  it "lets the user review current and historical rolls from the post menu" do
    topic_page.visit_topic(topic)
    page.refresh

    expect(topic_page).to have_roll_history_button(post)

    topic_page.open_roll_history(post)

    expect(roll_history_modal).to be_open
    expect(roll_history_modal.row_count).to eq(3)
    expect(roll_history_modal.entry_count(notation: "1d6", status: "Current")).to eq(1)
    expect(roll_history_modal.entry_count(notation: "1d6", status: "Historical")).to eq(1)
    expect(roll_history_modal).to have_entry(notation: "1d8", status: "Historical")
  end

  def process_rolls(post, raw = post.raw)
    post.update!(raw: raw)
    cpp = CookedPostProcessor.new(post)
    cpp.post_process
    post.update_column(:cooked, cpp.html)
    post.reload
  end
end
