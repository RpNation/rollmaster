# frozen_string_literal: true

RSpec.describe Rollmaster::RollController, type: :request do
  before { SiteSetting.rollmaster_enabled = true }

  describe "GET /rollmaster/roll" do
    let(:endpoint) { "/rollmaster/roll.json" }

    context "when valid dice rolls are provided" do
      it "returns the correct results" do
        get "/rollmaster/roll.json", params: { diceRolls: %w[2d6 1d20] }
        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["result"]).to be_an(Array)
        expect(json["result"].size).to eq(2)
      end
    end

    context "when no dice rolls are provided" do
      it "raises an invalid parameters error" do
        get "/rollmaster/roll.json"
        expect(response.status).to eq(400)
      end
    end

    context "when an invalid dice roll is provided" do
      before do
        allow(::Rollmaster::DiceEngine).to receive(:roll).and_raise(
          ::Rollmaster::DiceEngine::RollError,
          "Invalid dice roll",
        )
      end

      it "raises an invalid parameters error" do
        get "/rollmaster/roll.json", params: { diceRolls: ["invalid"] }
        expect(response.status).to eq(400)
      end
    end
  end
end
