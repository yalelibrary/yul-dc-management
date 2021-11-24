# frozen_string_literal: true
require "rails_helper"

RSpec.describe ApplicationCable::Connection do
  it "exists" do
    expect(described_class).to be_a(Class)
    expect(described_class).not_to be_a(Hash)
    expect(described_class).not_to be_a(Array)
  end
end
