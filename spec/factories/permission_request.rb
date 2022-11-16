# frozen_string_literal: true

FactoryBot.define do
  factory :permission_request do
    parent_object { FactoryBot.create(:parent_object) }
    user { FactoryBot.create(:user) }
    permission_request_user { FactoryBot.create(:permission_request_user) }
    permission_set { FactoryBot.create(:permission_set) }
  end
end