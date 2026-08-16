# frozen_string_literal: true

RSpec.describe "Roll description rendering", type: :system do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:topic) { Fabricate(:topic, user: user) }
  fab!(:post) do
    Fabricate(:post, topic: topic, user: user, raw: '[roll=“x" onmouseover="alert(1)”]1d6[/roll]')
  end

  let(:topic_page) { PageObjects::Pages::Topic.new }

  before do
    enable_current_plugin
    SiteSetting.rollmaster_enabled = true
    process_rolls(post)
    sign_in(user)
  end

  it "does not turn a description into an HTML attribute" do
    topic_page.visit_topic(topic)

    roll = page.find("#post_#{post.post_number} .bb-rollmaster-result")
    expect(roll["data-desc"]).to eq('x" onmouseover="alert(1)')
    expect(roll["onmouseover"]).to be_nil
  end

  def process_rolls(post)
    cpp = CookedPostProcessor.new(post)
    cpp.post_process
    post.update_column(:cooked, cpp.html)
  end
end
