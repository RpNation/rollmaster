# frozen_string_literal: true

Rollmaster::Engine.routes.draw { get "/rolls/:post_id" => "roll#rolls" }

Discourse::Application.routes.draw { mount ::Rollmaster::Engine, at: "rollmaster" }
