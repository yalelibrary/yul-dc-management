# frozen_string_literal: true

require "rails_helper"

RSpec.describe BatchProcessEventsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/batch_process_events").to route_to("batch_process_events#index")
    end

    it "routes to #show" do
      expect(get: "/batch_process_events/1").to route_to("batch_process_events#show", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/batch_process_events/1").to route_to("batch_process_events#destroy", id: "1")
    end
  end
end
