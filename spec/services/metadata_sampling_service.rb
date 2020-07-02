# frozen_string_literal: true
require "rails_helper"

WebMock.allow_net_connect!

RSpec.describe MetadataSamplingService do

  it "has a default file path to the public oids" do
    described_class.ladybird_field_statistics
  end

end
