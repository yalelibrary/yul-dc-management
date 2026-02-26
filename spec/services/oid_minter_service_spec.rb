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
  context 'when in yul-dc-demo cluster environment' do
    around do |example|
      original_cluster_name = ENV['CLUSTER_NAME']
      ENV['CLUSTER_NAME'] = 'yul-dc-demo'
      example.run
      ENV['CLUSTER_NAME'] = original_cluster_name
    end
    it 'initializes the sequence with the expected value' do
      oids = described_class.generate_oids(1)
      expect(oids[0]).to be >= 20_000_000
    end
  end
  context 'when in yul-dc-test cluster environment' do
    around do |example|
      original_cluster_name = ENV['CLUSTER_NAME']
      ENV['CLUSTER_NAME'] = 'yul-dc-test'
      example.run
      ENV['CLUSTER_NAME'] = original_cluster_name
    end
    it 'initializes the sequence with the expected value' do
      oids = described_class.generate_oids(1)
      expect(oids[0]).to be >= 40_000_000
    end
  end
  context 'when in yul-dc-uat cluster environment' do
    around do |example|
      original_cluster_name = ENV['CLUSTER_NAME']
      ENV['CLUSTER_NAME'] = 'yul-dc-uat'
      example.run
      ENV['CLUSTER_NAME'] = original_cluster_name
    end
    it 'initializes the sequence with the expected value' do
      oids = described_class.generate_oids(1)
      expect(oids[0]).to be >= 50_000_000
    end
  end
  context 'when in yul-dc-prod cluster environment' do
    around do |example|
      original_cluster_name = ENV['CLUSTER_NAME']
      ENV['CLUSTER_NAME'] = 'yul-dc-prod'
      example.run
      ENV['CLUSTER_NAME'] = original_cluster_name
    end
    it 'initializes the sequence with the expected value' do
      oids = described_class.generate_oids(1)
      expect(oids[0]).to be >= 30_000_000
    end
  end
  context 'when in test environment' do
    around do |example|
      original_environment_name = ENV['RAILS_ENV']
      ENV['RAILS_ENV'] = 'test'
      example.run
      ENV['RAILS_ENV'] = original_environment_name
    end
    it 'initializes the sequence with the expected value' do
      oids = described_class.generate_oids(1)
      expect(oids[0]).to be >= 200_000_000
    end
  end
  context 'when in development environment' do
    around do |example|
      original_environment_name = ENV['RAILS_ENV']
      ENV['RAILS_ENV'] = 'development'
      example.run
      ENV['RAILS_ENV'] = original_environment_name
    end
    it 'initializes the sequence with the expected value' do
      oids = described_class.generate_oids(1)
      expect(oids[0]).to be >= 100_000_000
    end
  end
end
