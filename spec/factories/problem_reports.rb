# frozen_string_literal: true

FactoryBot.define do
  factory :problem_report do
    child_count { 1 }
    parent_count { 1 }
    problem_parent_count { 1 }
    problem_child_count { 1 }
  end
end
