# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetsRecord, type: :model do
  context "When an initialized value is set" do
    it "uses the correct value" do
      oid = "2004628"
      source = "ladybird"
      mets_record = MetsRecord.new(oid, source)
      expect(mets_record.oid).to eq(oid)
      expect(mets_record.source).to eq(source)
    end
  end
end
