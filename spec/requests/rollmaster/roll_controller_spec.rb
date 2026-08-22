# frozen_string_literal: true

RSpec.describe Rollmaster::RollController, type: :request do
  before { SiteSetting.rollmaster_enabled = true }

  describe "GET /rollmaster/rolls/:post_id" do
    fab!(:post) { Fabricate(:post, raw: "[roll]2d6[/roll]") }
    fab!(:roll) { Fabricate(:rollmaster_roll, post: post) }

    it "returns the post's rolls when the post is visible to the current user" do
      get "/rollmaster/rolls/#{post.id}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["rolls"].map { |r| r["id"] }).to contain_exactly(roll.id)
    end

    it "404s for a post in a category the current user can't see" do
      group = Fabricate(:group)
      category = Fabricate(:private_category, group: group)
      restricted_post = Fabricate(:post, topic: Fabricate(:topic, category: category))
      Fabricate(:rollmaster_roll, post: restricted_post)
      sign_in(Fabricate(:user))

      get "/rollmaster/rolls/#{restricted_post.id}.json"

      expect(response.status).to eq(404)
    end

    it "404s a regular user but succeeds for staff on a trashed post" do
      trashed_post = Fabricate(:post, raw: "[roll]2d6[/roll]")
      trashed_roll = Fabricate(:rollmaster_roll, post: trashed_post)
      PostDestroyer.new(Fabricate(:admin), trashed_post).destroy

      sign_in(Fabricate(:user))
      get "/rollmaster/rolls/#{trashed_post.id}.json"
      expect(response.status).to eq(404)

      sign_in(Fabricate(:admin))
      get "/rollmaster/rolls/#{trashed_post.id}.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["rolls"].map { |r| r["id"] }).to contain_exactly(trashed_roll.id)
    end

    it "404s for a post_id that doesn't exist" do
      get "/rollmaster/rolls/#{Post.maximum(:id).to_i + 1}.json"

      expect(response.status).to eq(404)
    end
  end

  describe "GET /rollmaster/roll" do
    let(:endpoint) { "/rollmaster/roll.json" }

    context "when valid dice rolls are provided" do
      it "returns an ok result per notation" do
        get "/rollmaster/roll.json", params: { diceRolls: %w[2d6 1d20] }
        expect(response).to have_http_status(:ok)
        result = response.parsed_body["result"]
        expect(result.size).to eq(2)
        expect(result).to all(include("ok" => true))
      end
    end

    context "when no dice rolls are provided" do
      it "raises an invalid parameters error" do
        get "/rollmaster/roll.json"
        expect(response.status).to eq(400)
      end
    end

    context "when an invalid dice roll is provided" do
      it "returns a non-ok result for that notation instead of failing the request" do
        get "/rollmaster/roll.json", params: { diceRolls: ["invalid"] }
        expect(response).to have_http_status(:ok)
        result = response.parsed_body["result"]
        expect(result.size).to eq(1)
        expect(result.first["ok"]).to eq(false)
      end
    end
  end
end
