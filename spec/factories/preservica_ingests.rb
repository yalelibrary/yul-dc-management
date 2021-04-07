FactoryBot.define do
  factory :preservica_ingest do
    ingest_time { "2021-04-07 15:33:30" }
    parent_oid { "" }
    child_oid { "" }
    preservica_id { "MyString" }
    preservica_child_id { "MyString" }
    batch_process_id { "" }
  end
end
