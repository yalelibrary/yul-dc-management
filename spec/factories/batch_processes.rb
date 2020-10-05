# frozen_string_literal: true

FactoryBot.define do
  factory :batch_process do
    csv { "MyText" }
    mets_xml { "" }
    created_by { "MyString" }
    oid { "" }
  end
end
