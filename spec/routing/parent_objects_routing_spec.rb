# frozen_string_literal: true

require "rails_helper"

RSpec.describe ParentObjectsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/parent_objects").to route_to("parent_objects#index")
    end

    it "routes to #new" do
      expect(get: "/parent_objects/new").to route_to("parent_objects#new")
    end

    it "routes to #show" do
      expect(get: "/parent_objects/1").to route_to("parent_objects#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/parent_objects/1/edit").to route_to("parent_objects#edit", id: "1")
    end

    it "routes to #create" do
      expect(post: "/parent_objects").to route_to("parent_objects#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/parent_objects/1").to route_to("parent_objects#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/parent_objects/1").to route_to("parent_objects#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/parent_objects/1").to route_to("parent_objects#destroy", id: "1")
    end
  end
end
