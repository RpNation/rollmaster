# frozen_string_literal: true

module ::Rollmaster
  class RollController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    # GET /rollmaster/roll
    # @param [Array<String>] diceRolls array of dice rolls to be
    # @return [Hash] result array of per-notation results, each either
    #   {"ok" => true, "value" => ...} or {"ok" => false, "name" => ..., "msg" => ...}
    # @example URL /rollmaster/roll?diceRolls[]=2d6&diceRolls[]=1d20
    def roll
      raise Discourse::InvalidParameters, "diceRolls is required" if params[:diceRolls].blank?

      result = ::Rollmaster::DiceEngine.roll(*params[:diceRolls])
      render json: { result: result }
    end

    # GET /rollmaster/rolls/:post_id
    # @param [Integer] post_id the ID of the post to get rolls for
    # @return [Array<Hash>] rolls array of rolls associated with the post
    # @example URL /rollmaster/rolls/123
    def rolls
      post_id = params[:post_id]
      raise Discourse::InvalidParameters, "post_id is required" if post_id.blank?

      post = Post.with_deleted.find_by(id: post_id)
      raise Discourse::NotFound unless guardian.can_see?(post)

      rolls = ::Rollmaster::Roll.where(post_id: post_id).order(created_at: :desc, id: :desc)
      render_serialized(rolls, Rollmaster::RollSerializer, root: "rolls")
    end
  end
end
