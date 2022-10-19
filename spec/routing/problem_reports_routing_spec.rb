# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProblemReportsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/problem_reports").to route_to("problem_reports#index")
    end
  end
end
