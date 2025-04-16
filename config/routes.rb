# frozen_string_literal: true

Rollmaster::Engine.routes.draw do
  get "/examples" => "examples#index"
  # define routes here
end

Discourse::Application.routes.draw { mount ::Rollmaster::Engine, at: "rollmaster" }
