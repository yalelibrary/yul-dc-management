# frozen_string_literal: true
require "rails_helper"

RSpec.describe ApplicationJob do
  it "should exists" do
    expect(ApplicationJob).to be_a(Class)
  end
end
