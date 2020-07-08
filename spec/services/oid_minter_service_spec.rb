# frozen_string_literal: true
require 'rails_helper'

describe OidMinterService do
  context 'when requesting OIDs' do
    it 'succeeds for a single OID' do
      oids = described_class.generate_oids(1)
      expect(oids).to be_a Array
      expect(oids.length).to equal 1
      expect(oids[0]).to be_a Integer
    end

    it 'succeeds for multiple OIDs' do
      number = 5
      oids = described_class.generate_oids(number)
      expect(oids).to be_a Array
      expect(oids.length).to equal number
      expect(oids).to all(be_a Integer)
    end

    it 'returns unique OIDs' do
      number = 10
      oids = described_class.generate_oids(number)
      expect(oids.length).to equal number
      expect(oids.length).to equal oids.uniq.length
    end
  end
end
