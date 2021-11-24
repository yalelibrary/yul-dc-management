# frozen_string_literal: true
require "rails_helper"

RSpec.describe ApplicationCable::Connection do
  it "exists as a class" do
    expect(described_class).to be_a(Class)
  end
  it "is not an array" do
    expect(described_class).not_to be_a(Array)
  end
  it "is not a hash" do
    expect(described_class).not_to be_a(Hash)
  end
end
