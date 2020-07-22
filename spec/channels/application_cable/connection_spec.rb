# frozen_string_literal: true
require "rails_helper"

RSpec.describe ApplicationCable::Connection do
  it "should exists" do
    expect(ApplicationCable::Connection).to be_a(Class)
  end
end
