# frozen_string_literal: true

require "rails_helper"

RSpec.describe MetsXmlImportsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/mets_xml_imports").to route_to("mets_xml_imports#index")
    end

    it "routes to #new" do
      expect(get: "/mets_xml_imports/new").to route_to("mets_xml_imports#new")
    end

    it "routes to #show" do
      expect(get: "/mets_xml_imports/1").to route_to("mets_xml_imports#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/mets_xml_imports/1/edit").to route_to("mets_xml_imports#edit", id: "1")
    end

    it "routes to #create" do
      expect(post: "/mets_xml_imports").to route_to("mets_xml_imports#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/mets_xml_imports/1").to route_to("mets_xml_imports#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/mets_xml_imports/1").to route_to("mets_xml_imports#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/mets_xml_imports/1").to route_to("mets_xml_imports#destroy", id: "1")
    end
  end
end
