# frozen_string_literal: true
require "rails_helper"

RSpec.describe ApplicationCable::Channel do
  it "should exists" do
    expect(ApplicationCable::Channel).to be_a(Class)
  end
end
