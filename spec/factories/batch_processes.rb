# frozen_string_literal: true

FactoryBot.define do
  factory :batch_process do
    csv { "MyText" }
    mets_xml { "" }
    user { FactoryBot.create(:user) }
    oid { "" }
  end
end
