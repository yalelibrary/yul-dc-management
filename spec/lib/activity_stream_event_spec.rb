# frozen_string_literal: true
require "rails_helper"
require "support/time_helpers"

RSpec.describe ActivityStreamEvent do
  let(:ase) { described_class.new }

  it "can be instantiated" do
    ase
  end
end
