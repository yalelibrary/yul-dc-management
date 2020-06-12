# frozen_string_literal: true

FactoryBot.define do
  factory :parent_object do
    oid { "MyString" }
    bib_id { "MyString" }
    # holding_id { "MyString" }
    # item_id { "MyString" }
    # barcode { "MyString" }
    # aspace_uri { "MyString" }
    last_mc_update { "2020-06-10 17:38:27" }
    factory :parent_object_with_bib_id do
      oid { "2004628" }
      bib_id { "3163155" }
    end
    factory :parent_object_with_aspace_uri do
      oid { "16854285" }
      bib_id { "12307100" }
      barcode { "39002102340669" }
      aspace_uri { "/repositories/11/archival_objects/515305" }
    end
  end
end
