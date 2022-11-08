# frozen_string_literal: true

FactoryBot.define do
  factory :permission_request_user do
    sub { "subject" }
    name { "User Name" }
    email { "user@example.com" }
    email_verified { true }
    oidc_updated_at { "2022-11-08 15:33:30" }
  end
end
