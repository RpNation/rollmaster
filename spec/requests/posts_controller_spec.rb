# frozen_string_literal: true

RSpec.describe PostsController, type: :request do
  fab!(:user)
  fab!(:topic) { Fabricate(:topic, user: user) }

  let(:post) { Fabricate(:post, topic: topic, user: user, raw: "Opening roll: [roll]1d6[/roll]") }

  before do
    enable_current_plugin
    SiteSetting.rollmaster_enabled = true
    SiteSetting.editing_grace_period = 0

    process_initial_roll_state(post)
    revise_post(post, "Changed roll: [roll]1d8[/roll]")
    revise_post(post, "Back again: [roll]1d6[/roll]")

    sign_in(user)
  end

  describe "#latest_revision" do
    it "includes roll changes for the compared revisions" do
      get "/posts/#{post.id}/revisions/latest.json"

      expect(response).to have_http_status(:ok)
      expect(
        response.parsed_body.dig("roll_changes", "previous").map { |entry| entry["notation"] },
      ).to eq(["1d8"])
      expect(
        response.parsed_body.dig("roll_changes", "current").map { |entry| entry["notation"] },
      ).to eq(["1d6"])
      expect(response.parsed_body.dig("roll_changes", "current").first["id"]).not_to eq(
        response.parsed_body.dig("roll_changes", "previous").first["id"],
      )
    end
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
