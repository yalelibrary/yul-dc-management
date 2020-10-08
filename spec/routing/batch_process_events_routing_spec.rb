require "rails_helper"

RSpec.describe BatchProcessEventsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/batch_process_events").to route_to("batch_process_events#index")
    end

    it "routes to #new" do
      expect(get: "/batch_process_events/new").to route_to("batch_process_events#new")
    end

    it "routes to #show" do
      expect(get: "/batch_process_events/1").to route_to("batch_process_events#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/batch_process_events/1/edit").to route_to("batch_process_events#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/batch_process_events").to route_to("batch_process_events#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/batch_process_events/1").to route_to("batch_process_events#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/batch_process_events/1").to route_to("batch_process_events#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/batch_process_events/1").to route_to("batch_process_events#destroy", id: "1")
    end
  end
end
