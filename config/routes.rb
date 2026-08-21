# frozen_string_literal: true

Rollmaster::Engine.routes.draw do
  get "/roll" => "roll#roll"
  get "/rolls/:post_id" => "roll#rolls"
end

Discourse::Application.routes.draw { mount ::Rollmaster::Engine, at: "rollmaster" }
