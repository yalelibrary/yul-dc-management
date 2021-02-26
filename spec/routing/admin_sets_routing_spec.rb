# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminSetsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/admin_sets").to route_to("admin_sets#index")
    end

    it "routes to #new" do
      expect(get: "/admin_sets/new").to route_to("admin_sets#new")
    end

    it "routes to #show" do
      expect(get: "/admin_sets/1").to route_to("admin_sets#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/admin_sets/1/edit").to route_to("admin_sets#edit", id: "1")
    end

    it "routes to #create" do
      expect(post: "/admin_sets").to route_to("admin_sets#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/admin_sets/1").to route_to("admin_sets#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/admin_sets/1").to route_to("admin_sets#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/admin_sets/1").to route_to("admin_sets#destroy", id: "1")
    end
  end
end
