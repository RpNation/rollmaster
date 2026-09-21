# frozen_string_literal: true

module ::Rollmaster
  class RollController < ::ApplicationController
    requires_plugin PLUGIN_NAME

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
