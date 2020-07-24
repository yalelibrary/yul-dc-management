# frozen_string_literal: true
require "rails_helper"

RSpec.describe ApplicationJob do
  it "existses" do
    expect(described_class).to be_a(Class)
  end
end
