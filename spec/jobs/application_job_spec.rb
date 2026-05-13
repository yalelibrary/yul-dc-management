# frozen_string_literal: true
require "rails_helper"

RSpec.describe ApplicationJob do
  it "exists" do
    expect(described_class).to be_a(Class)
  end

  it "has correct priority" do
    application_job = described_class.new
    expect(application_job.default_priority).to eq(40)
  end
end
