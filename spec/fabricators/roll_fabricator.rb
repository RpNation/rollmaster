# frozen_string_literal: true

Fabricator(:rollmaster_roll, class_name: "Rollmaster::Roll") do
  post
  raw { "2d6" }
  notation { "2d6" }
  result { "[3, 4] = 7" }
end
