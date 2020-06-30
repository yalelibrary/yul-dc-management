# frozen_string_literal: true

FactoryBot.define do
  factory :activity_stream_log do
    run_time { "2020-06-12 18:27:44" }
    activity_stream_items { 673 }
    retrieved_records { 4 }
    status { "Success" }
    factory :successful_activity_stream_log do
      status { "Success" }
    end
    factory :failed_activity_stream_log do
      status { "Failed" }
    end
  end
end
