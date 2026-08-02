# frozen_string_literal: true

RSpec.describe "Post history rolls", type: :system do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:topic) { Fabricate(:topic, user: user) }

  let(:post) { Fabricate(:post, topic: topic, user: user, raw: "Opening roll: [roll]1d6[/roll]") }
  let(:post_history_modal) { PageObjects::Modals::RollmasterPostHistory.new }
  let(:topic_page) { PageObjects::Pages::Topic.new }

  before do
    enable_current_plugin
    SiteSetting.rollmaster_enabled = true
    SiteSetting.editing_grace_period = 0

    process_initial_roll_state(post)
    revise_post(post, "Changed roll: [roll]1d8[/roll]")
    revise_post(post, "Back again: [roll]1d6[/roll]")

    sign_in(user)
  end

  it "shows roll changes while the user browses post history" do
    topic_page.visit_topic(topic)
    page.refresh

    topic_page.open_post_history(post)

    expect(post_history_modal.current_roll_entries.size).to eq(1)
    expect(post_history_modal.previous_roll_entries.size).to eq(1)
    expect(post_history_modal).to have_current_roll_entry("1d6")
    expect(post_history_modal).to have_previous_roll_entry("1d8")

    post_history_modal.click_previous_revision

    expect(post_history_modal.current_roll_entries.size).to eq(1)
    expect(post_history_modal.previous_roll_entries.size).to eq(1)
    expect(post_history_modal).to have_current_roll_entry("1d8")
    expect(post_history_modal).to have_previous_roll_entry("1d6")
  end

  def process_initial_roll_state(post)
    cpp = CookedPostProcessor.new(post)
    cpp.post_process
    post.update_column(:cooked, cpp.html)
    post.reload
  end

  def revise_post(post, raw)
    PostRevisor.new(post).revise!(user, { raw: raw, edit_reason: "reroll" })
    cpp = CookedPostProcessor.new(post)
    cpp.post_process
    post.update_column(:cooked, cpp.html)
    post.reload
  end
end
