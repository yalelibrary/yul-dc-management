# frozen_string_literal: true
require "rails_helper"

RSpec.describe ActivityStreamReader do
  let(:asr) { described_class.new }

  it "can be instantiated" do
    asr
    expect(asr).to be_instance_of(described_class)
  end

  it "can call for updates" do
    described_class.update
  end
end
