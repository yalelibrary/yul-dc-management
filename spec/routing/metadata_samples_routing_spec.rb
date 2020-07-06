# frozen_string_literal: true

require "rails_helper"

RSpec.describe MetadataSamplesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/metadata_samples").to route_to("metadata_samples#index")
    end

    it "routes to #new" do
      expect(get: "/metadata_samples/new").to route_to("metadata_samples#new")
    end

    it "routes to #show" do
      expect(get: "/metadata_samples/1").to route_to("metadata_samples#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/metadata_samples/1/edit").to route_to("metadata_samples#edit", id: "1")
    end

    it "routes to #create" do
      expect(post: "/metadata_samples").to route_to("metadata_samples#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/metadata_samples/1").to route_to("metadata_samples#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/metadata_samples/1").to route_to("metadata_samples#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/metadata_samples/1").to route_to("metadata_samples#destroy", id: "1")
    end
  end
end
