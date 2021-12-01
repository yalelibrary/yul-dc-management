# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IngestEvent, type: :model do
  it "exists" do
    expect(described_class).to be_a(Class)
  end

  it { is_expected.to belong_to :batch_connection }
end
