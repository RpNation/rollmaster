# frozen_string_literal: true

RSpec.describe "Disabled Rollmaster", type: :system do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:topic) { Fabricate(:topic, user: user) }
  fab!(:post) { Fabricate(:post, topic: topic, user: user) }

  let(:composer) { PageObjects::Components::Composer.new }
  let(:topic_page) { PageObjects::Pages::Topic.new }
  let(:roll_bbcode) { "[roll]2d6[/roll]" }

  before do
    enable_current_plugin
    SiteSetting.rollmaster_enabled = false
    sign_in(user)
  end

  it "preserves roll BBCode when posting" do
    topic_page.visit_topic(topic)
    topic_page.click_post_action_button(post, :reply)

    composer.fill_content(roll_bbcode)
    composer.submit

    reply = topic.posts.order(:id).last
    expect(reply.raw).to eq(roll_bbcode)
    expect(topic_page).to have_post_content(post_number: reply.post_number, content: roll_bbcode)
    expect(reply.cooked).not_to include('class="bb-rollmaster"')
    expect(::Rollmaster::Roll.where(post_id: reply.id)).to be_empty
  end
end
