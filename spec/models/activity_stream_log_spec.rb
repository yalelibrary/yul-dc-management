# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityStreamLog, type: :model do
  let(:asl) { FactoryBot.create(:activity_stream_log) }

  it "has all expected fields" do
    asl

    expect(asl.run_time).to eq "2020-06-12 18:27:44"
    expect(asl.object_count).to eq 673
    expect(asl.status).to eq "Success"
  end
end
