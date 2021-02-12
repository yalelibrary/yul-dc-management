# frozen_string_literal: true
#
require 'rails_helper'

RSpec.describe MetsDirectoryScanner do
  let(:user) { described_class.system_user }
  let(:mets_file) do
    ActionDispatch::Http::UploadedFile.new(
      filename: File.basename("test_mets.xml"),
      type: 'text/xml',
      tempfile: File.new("#{ENV['GOOBI_SCAN_DIRECTORIES']}/001/test_mets.xml")
    )
  end
  let(:batch_process) { FactoryBot.create(:batch_process, batch_action: 'create parent objects', user: user, file: mets_file) }
  let(:progress_file_1) { "#{ENV['GOOBI_SCAN_DIRECTORIES']}/001/#{described_class.indicator_file_prefix}.progress" }
  let(:progress_file_2) { "#{ENV['GOOBI_SCAN_DIRECTORIES']}/002/#{described_class.indicator_file_prefix}.progress" }
  let(:progress_file_3) { "#{ENV['GOOBI_SCAN_DIRECTORIES']}/003/#{described_class.indicator_file_prefix}.progress" }
  let(:done_file_1) { "#{ENV['GOOBI_SCAN_DIRECTORIES']}/001/#{described_class.indicator_file_prefix}.done" }
  let(:done_file_2) { "#{ENV['GOOBI_SCAN_DIRECTORIES']}/002/#{described_class.indicator_file_prefix}.done" }
  let(:done_file_3) { "#{ENV['GOOBI_SCAN_DIRECTORIES']}/003/#{described_class.indicator_file_prefix}.done" }

  around do |example|
    original_goobi_scan_directories = ENV['GOOBI_SCAN_DIRECTORIES']
    ENV['GOOBI_SCAN_DIRECTORIES'] = Rails.root.join("spec", "fixtures", "scan_test", "dcs").to_s
    example.run
    ENV['GOOBI_SCAN_DIRECTORIES'] = original_goobi_scan_directories
  end

  before do
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(BatchProcess).to receive(:validate_import).and_return(nil)
    # rubocop:enable RSpec/AnyInstance
    # (They should be cleaned up by after, but just in case some got left behind)
    clean_up_files
  end

  after do
    clean_up_files
  end

  def clean_up_files
    # files ending with _3 should never exist, but may because of a problem with the code, so cleanup, just in case
    [progress_file_1, progress_file_2, progress_file_3, done_file_1, done_file_2, done_file_3].each do |file|
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
    File.new(done_file_1, "w")
    expect(BatchProcess).to receive(:new).exactly(1).times.and_return(batch_process)
    expect(File.exist?(done_file_2)).to be_falsey
    described_class.perform_scan
    expect(File.exist?(done_file_2)).to be_truthy
  end

  it "will skip directory with young enough progress file" do
    File.new(progress_file_2, "w")
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

  describe "when GOOBI_SCAN_DIRECTORIES doesn't exists, but GOOBI_MOUNT does" do
    around do |example|
      progress_file_1
      progress_file_2
      progress_file_3
      done_file_1
      done_file_2
      done_file_3
      mets_file
      original_goobi_scan_directories = ENV['GOOBI_SCAN_DIRECTORIES']
      ENV['GOOBI_SCAN_DIRECTORIES'] = nil
      original_goobi_mount = ENV['GOOBI_MOUNT']
      ENV['GOOBI_MOUNT'] = Rails.root.join("spec", "fixtures", "scan_test").to_s
      example.run
      ENV['GOOBI_SCAN_DIRECTORIES'] = original_goobi_scan_directories
      ENV['GOOBI_MOUNT'] = original_goobi_mount
    end

    it "will scan a directory using GOOBI_MOUNT" do
      expect(BatchProcess).to receive(:new).exactly(2).times.and_return(batch_process)
      expect(File.exist?(done_file_1)).to be_falsey
      expect(File.exist?(done_file_2)).to be_falsey
      described_class.perform_scan
      expect(File.exist?(done_file_1)).to be_truthy
      expect(File.exist?(done_file_2)).to be_truthy
    end
  end
end
