# frozen_string_literal: true
require "rails_helper"

RSpec.describe ApplicationMailer do
  it "should exists" do
    expect(ApplicationMailer).to be_a(Class)
  end
end
