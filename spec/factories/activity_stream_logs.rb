# frozen_string_literal: true

FactoryBot.define do
  factory :activity_stream_log do
    run_time { "2020-06-12 18:27:44" }
    object_count { 673 }
    status { "Success" }
  end
end
