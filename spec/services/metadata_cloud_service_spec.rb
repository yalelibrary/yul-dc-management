# frozen_string_literal: true
require "rails_helper"
require "webmock"

WebMock.allow_net_connect!

# Try with adding gem 'http', '~> 4.4', '>= 4.4.1' to gemfile and use basic auth from there

RSpec.describe MetadataCloudService do
  let(:mcs) { described_class.new }
  let(:example_request) { Net::HTTP.get('www.example.com', '/') }

  it "can be instantiated" do
    expect(mcs).to be_instance_of(described_class)
  end

  it "can connect to an external website" do
    expect(example_request).to include "Example Domain"
  end

  it "can connect using http auth" do
    true
  end
end
