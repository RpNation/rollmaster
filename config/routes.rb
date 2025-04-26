# frozen_string_literal: true

Rollmaster::Engine.routes.draw do
  get "/roll" => "roll#roll"
  # define routes here
end

Discourse::Application.routes.draw { mount ::Rollmaster::Engine, at: "rollmaster" }
