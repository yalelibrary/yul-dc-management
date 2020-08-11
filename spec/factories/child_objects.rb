FactoryBot.define do
  factory :child_object do
    child_oid { "MyString" }
    caption { "MyString" }
    width { 1 }
    height { 1 }
    order { 1 }
    parent_object { nil }
  end
end
