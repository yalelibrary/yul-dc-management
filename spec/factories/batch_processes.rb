# frozen_string_literal: true

FactoryBot.define do
  factory :batch_process do
    csv { nil }
    mets_xml { nil }
    user { nil }
    oid { nil }
  end
end
