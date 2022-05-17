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
    fixtures = File.readlines('spec/fixtures/preservica/api/entity/information-objects/b3ffec3c-bb42-4a72-90ee-3f38bc364f02/b3ffec3c-bb42-4a72-90ee-3f38bc364f02_fixtures.txt')
    fixtures.each do |fixture|
      fixture.chomp!
      stub_request(:get, "https://test#{fixture}").to_return(
        status: 200, body: File.open(File.join(fixture_path, "#{fixture}.xml"))
      )
    end
  end

  context "when there are non-tiff bitstreams" do
    it "only include the tifs" do
      image_service = PreservicaImageService.new("information-objects/b3ffec3c-bb42-4a72-90ee-3f38bc364f02", "brbl")
      image_list = image_service.image_list("preservica_preservation")
      expect(image_list.count).to be(80)
    end
  end
end
