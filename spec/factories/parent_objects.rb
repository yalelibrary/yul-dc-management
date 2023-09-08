# frozen_string_literal: true

FactoryBot.define do
  factory :parent_object do
    admin_set { AdminSet.first.presence || FactoryBot.create(:admin_set) }
    oid { "2004628" }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
    factory :parent_object_with_bib do
      oid { "2004628" }
      bib { "3163155" }
    end
    factory :parent_object_with_aspace_uri do
      oid { "16854285" }
      bib { "12307100" }
      barcode { "39002102340669" }
      aspace_uri { "/repositories/11/archival_objects/515305" }
    end
  end
end
