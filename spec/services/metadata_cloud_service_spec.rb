# frozen_string_literal: true
require "rails_helper"
require "webmock"

WebMock.allow_net_connect!

# Try with adding gem 'http', '~> 4.4', '>= 4.4.1' to gemfile and use basic auth from there

RSpec.describe MetadataCloudService do
  let(:mcs) { described_class.new }

  it "can connect to the metadata cloud using basic auth" do
    expect(mcs.mc_get.to_str).to include "Manuscript, on parchment"
  end
end
