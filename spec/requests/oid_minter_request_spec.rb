# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "Request new OIDs", type: :request do
  let(:user) { FactoryBot.create(:user) }
  describe "when authenticated" do
    context "Requesting a single OID" do
      before do
        login_as(user)
      end
      it "returns a successful JSON response" do
        get new_oid_path, headers: { 'ACCEPT' => "application/json" }
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
        get new_oid_path, headers: { 'ACCEPT' => "text/plain" }
        expect(response).to be_successful
        expect(response.content_type).to eq "text/plain; charset=utf-8"
        expect(response.body.to_i).to be_a Integer
      end
    end

    context "Requesting multiple OIDs" do
      before do
        login_as(user)
      end
      it "returns a successful JSON response" do
        number = 5
        get new_oid_path(number), headers: { 'ACCEPT' => "application/json" }
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
        number = 6
        get new_oid_path(number), headers: { 'ACCEPT' => "text/plain" }
        expect(response).to be_successful
        expect(response.content_type).to eq "text/plain; charset=utf-8"
        expect(response.body).not_to be_nil
        values = response.body.split("\n")
        expect(values).to be_a Array
        expect(values.length).to be number
        expect(values.map(&:to_i)).to all(be_a Integer)
      end

      it "returns an error when a non-integer is supplied" do
        number = "5%2E25"
        get new_oid_path(number), headers: { 'ACCEPT' => "application/json" }
        expect(response).to have_http_status(400)
        expect(response.content_type).to eq "text/plain; charset=utf-8"
      end

      it "returns an appropriate HTTP status for a non-JSON or text request" do
        get new_oid_path, headers: { 'ACCEPT' => "text/html" }
        expect(response).to have_http_status(406)
      end
    end

    context "logging an oid request" do
      before do
        login_as(user)
      end
      let(:logger_mock) { instance_double("Rails.logger").as_null_object }

      it 'logs the user email, ip address and OIDs' do
        allow(Rails.logger).to receive(:info) { :logger_mock }
        number = 5

        get new_oid_path(number), headers: { 'ACCEPT' => "application/json" }
        json_response = JSON.parse(response.body)
        oids = json_response['oids']
        request_ip = "127.0.0.1"

        expect(Rails.logger).to have_received(:info)
          .with("OIDs Created: {\"email\":\"#{user.email}\",\"ip_address\":\"#{request_ip}\",\"oids\":\"#{oids}\"}")
      end
    end
  end

  describe "when not authenticated" do
    context "requesting generate oids" do
      it "prevents access" do
        headers = { 'ACCEPT' => "application/json" }
        get new_oid_path, headers: headers

        expect(response.status).to be(401)
      end
    end
  end
end
