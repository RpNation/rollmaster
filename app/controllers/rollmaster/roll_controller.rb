# frozen_string_literal: true

module ::Rollmaster
  class RollController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    # GET /rollmaster/roll
    # @param [Array<String>] diceRolls array of dice rolls to be
    # @return [Hash] results array of dice rolls
    # @example URL /rollmaster/roll?diceRolls[]=2d6&diceRolls[]=1d20
    def roll
      begin
        result = ::Rollmaster::DiceEngine.roll(*params[:diceRolls])
        render json: { result: result }
      rescue ::Rollmaster::DiceEngine::RollError => e
        raise Discourse::InvalidParameters, e.message
      end
    end
  end
end
