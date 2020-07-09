# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "/api/oid", type: :request do
  context "Requesting a single OID" do
    it "returns a successful JSON response" do
      headers = { 'ACCEPT' => "application/json" }
      get new_oid_path, headers: headers
      expect(response).to be_successful
      expect(response.content_type).to eq "application/json; charset=utf-8"
      json_response = JSON.parse(response.body)
      expect(json_response['oids']).not_to be_nil
      oids = json_response['oids']
      expect(oids).to be_a Array
      expect(oids.length).to be 1
      expect(oids[0]).to be_a Integer
    end

    it "returns a successful text response" do
      headers = { 'ACCEPT' => "text/plain" }
      get new_oid_path, headers: headers
      expect(response).to be_successful
      expect(response.content_type).to eq "text/plain; charset=utf-8"
      expect(response.body.to_i).to be_a Integer
    end
  end

  context "Requesting multiple OIDs" do
    it "returns a successful JSON response" do
      headers = { 'ACCEPT' => "application/json" }
      number = 5
      get new_oid_path(number), headers: headers
      expect(response).to be_successful
      expect(response.content_type).to eq "application/json; charset=utf-8"
      json_response = JSON.parse(response.body)
      expect(json_response['oids']).not_to be_nil
      oids = json_response['oids']
      expect(oids).to be_a Array
      expect(oids.length).to be number
      expect(oids).to all(be_a Integer)
    end

    it "returns a successful text response" do
      headers = { 'ACCEPT' => "text/plain" }
      number = 6
      get new_oid_path(number), headers: headers
      expect(response).to be_successful
      expect(response.content_type).to eq "text/plain; charset=utf-8"
      expect(response.body).not_to be_nil
      values = response.body.split("\n")
      expect(values).to be_a Array
      expect(values.length).to be number
      expect(values.map(&:to_i)).to all(be_a Integer)
    end

    it "returns an error when a non-integer is supplied" do
      headers = { 'ACCEPT' => "application/json" }
      number = "5%2E25"
      get new_oid_path(number), headers: headers
      expect(response).to have_http_status(400)
      expect(response.content_type).to eq "text/plain; charset=utf-8"
    end

    it "returns an appropriate HTTP status for a non-JSON or text request" do
      headers = { 'ACCEPT' => "text/html" }
      get new_oid_path, headers: headers
      expect(response).to have_http_status(406)
    end
  end
end
