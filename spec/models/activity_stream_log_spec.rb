# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityStreamLog, type: :model do
  let(:asl) { FactoryBot.create(:activity_stream_log) }

  it "has all expected fields" do
    asl

    expect(asl.run_time).to eq "2023-05-01 18:27:44"
    expect(asl.activity_stream_items).to eq 673
    expect(asl.retrieved_records).to eq 4
    expect(asl.status).to eq "Success"
  end
end
