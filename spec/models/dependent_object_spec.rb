# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DependentObject, type: :model do
  it "exists" do
    expect(described_class).to be_a(Class)
  end

  it { is_expected.to belong_to :parent_object }
end
