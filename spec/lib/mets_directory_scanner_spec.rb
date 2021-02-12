# frozen_string_literal: true
#
require 'rails_helper'

RSpec.describe MetsDirectoryScanner do
  let(:user) { FactoryBot.create(:user) }
  let(:batch_process) { FactoryBot.create(:batch_process, user: user) }
  let(:progress_file_1) { "#{ENV['GOOBI_MOUNT']}/001/#{described_class.indicator_file_prefix}.progress" }
  let(:progress_file_2) { "#{ENV['GOOBI_MOUNT']}/002/#{described_class.indicator_file_prefix}.progress" }
  let(:done_file_1) { "#{ENV['GOOBI_MOUNT']}/001/#{described_class.indicator_file_prefix}.done" }
  let(:done_file_2) { "#{ENV['GOOBI_MOUNT']}/002/#{described_class.indicator_file_prefix}.done" }

  around do |example|
    original_metadata_cloud_host = ENV['GOOBI_MOUNT']
    ENV['GOOBI_MOUNT'] = Rails.root.join("spec", "fixtures", "scan_test").to_s
    example.run
    ENV['GOOBI_MOUNT'] = original_metadata_cloud_host
  end

  before do
    allow(batch_process).to receive(:validate_import).and_return(nil)
    # (They should be cleaned up by after, but just in case some got left behind)
    clean_up_files
  end

  after do
    clean_up_files
  end

  def clean_up_files
    [progress_file_1, progress_file_2, done_file_1, done_file_2].each do |file|
      File.delete(file) if File.exist?(file)
    end
  end

  it "will scan a directory and create jobs with progress file" do
    expect(BatchProcess).to receive(:new).exactly(2).times.and_return(batch_process)
    expect(File.exist?(done_file_1)).to be_falsey
    expect(File.exist?(done_file_2)).to be_falsey
    described_class.perform_scan
    expect(File.exist?(done_file_1)).to be_truthy
    expect(File.exist?(done_file_2)).to be_truthy
  end

  it "will skip directory with done file" do
    File.new("#{ENV['GOOBI_MOUNT']}/001/#{described_class.indicator_file_prefix}.done", "w")
    expect(BatchProcess).to receive(:new).exactly(1).times.and_return(batch_process)
    expect(File.exist?(done_file_2)).to be_falsey
    described_class.perform_scan
    expect(File.exist?(done_file_2)).to be_truthy
  end

  it "will skip directory with young enough progress file" do
    File.new("#{ENV['GOOBI_MOUNT']}/002/#{described_class.indicator_file_prefix}.progress", "w")
    expect(BatchProcess).to receive(:new).exactly(1).times.and_return(batch_process)
    expect(File.exist?(done_file_1)).to be_falsey
    described_class.perform_scan
    expect(File.exist?(done_file_1)).to be_truthy
  end

  it "will remove old progress file and process" do
    File.new(progress_file_1, "w")
    File.utime(Time.now.utc, Time.now.utc - 5.days, progress_file_1)
    expect(BatchProcess).to receive(:new).exactly(2).times.and_return(batch_process)
    expect(File.exist?(done_file_1)).to be_falsey
    expect(File.exist?(done_file_2)).to be_falsey
    described_class.perform_scan
    expect(File.exist?(done_file_1)).to be_truthy
    expect(File.exist?(done_file_2)).to be_truthy
  end
end
