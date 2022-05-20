# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Preservica::PreservicaObject, type: :model do
  around do |example|
    preservica_host = ENV['PRESERVICA_HOST']
    preservica_creds = ENV['PRESERVICA_CREDENTIALS']
    ENV['PRESERVICA_HOST'] = "testpreservica"
    ENV['PRESERVICA_CREDENTIALS'] = '{"brbl": {"username":"xxxxx", "password":"xxxxx"}}'
    example.run
    ENV['PRESERVICA_HOST'] = preservica_host
    ENV['PRESERVICA_CREDENTIALS'] = preservica_creds
  end

  before do
    stub_preservica_login
    stub_request(:get, "https://testpreservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c4/children").to_return(
      status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c4/children.xml"))
    )
  end

  context "when there token has expired" do
    before do
      Timecop.freeze(Time.zone.today)
    end

    after do
      Timecop.return
    end

    it "refresh the token" do
      preservica_client = PreservicaClient.new(admin_set_key: "brbl")
      preservica_client.login
      expect(preservica_client).to receive(:refresh).once
      now = Time.zone.today
      ActiveJob::Scheduler.start
      new_time = now + 15.minutes
      Timecop.travel(new_time)
      preservica_client.structural_object_children("7fe35e8c-c21a-444a-a2e2-e3c926b519c4")
    end
  end
end
