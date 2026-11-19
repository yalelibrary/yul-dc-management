# frozen_string_literal: true
#
require 'rails_helper'

RSpec.describe MetsDirectoryScanner do
  let(:user) { User.system_user }
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

  describe "when a mets file fails validation", prep_admin_sets: true, prep_metadata_sources: true do
    let(:scan_dir) { Dir.mktmpdir }
    let(:fixture_dir) { Rails.root.join("spec", "fixtures", "goobi", "metadata", "30000317_20201203_140947") }
    let(:checksum_package) { File.join(scan_dir, "checksum_package") }
    let(:rights_package) { File.join(scan_dir, "rights_package") }

    around do |example|
      ENV['GOOBI_SCAN_DIRECTORIES'] = scan_dir
      example.run
      FileUtils.remove_entry(scan_dir)
    end

    before do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(BatchProcess).to receive(:validate_import).and_call_original
      # rubocop:enable RSpec/AnyInstance
      FileUtils.mkdir_p([checksum_package, rights_package])
      FileUtils.cp(File.join(fixture_dir, "bad_checksum_mets.xml"), File.join(checksum_package, "checksum_mets.xml"))
      FileUtils.cp(File.join(fixture_dir, "no_rights_mets.xml"), File.join(rights_package, "rights_mets.xml"))
    end

    def indicator_file(package, extension)
      File.join(package, "#{described_class.indicator_file_prefix}.#{extension}")
    end

    it "fails the scan with every mets file that failed" do
      expect { described_class.perform_scan }.to raise_error(MetsDirectoryScanner::ScanError) { |error|
        expect(error.message).to start_with("2 mets files failed to ingest:")
        expect(error.message).to include("#{checksum_package}/checksum_mets.xml: Validation failed: File 4e870f62d9b11c7cd93520d1aa5fe3def9ad, index: 0 invalid checksum")
        expect(error.message).to include("#{rights_package}/rights_mets.xml: Validation failed: File no right statement found in the mets xml")
      }
    end

    it "creates a failed batch process with the Goobi images message for image errors and the actual error for others" do
      expect { described_class.perform_scan }.to raise_error(MetsDirectoryScanner::ScanError).and change(BatchProcess, :count).by(2)
      checksum_batch = BatchProcess.find_by(file_name: "checksum_mets.xml")
      rights_batch = BatchProcess.find_by(file_name: "rights_mets.xml")
      expect(checksum_batch.batch_ingest_events.pluck(:reason, :status)).to eq([[SetupMetadataJob::GOOBI_IMAGES_MESSAGE, "failed"]])
      expect(rights_batch.batch_ingest_events.pluck(:reason, :status)).to eq([["Ingest failed. no right statement found in the mets xml", "failed"]])
      expect(checksum_batch.batch_status).to eq("Batch failed")
      expect(ParentObject.count).to eq(0)
    end

    it "leaves the progress file so the mets files are skipped until it is a day old" do
      expect { described_class.perform_scan }.to raise_error(MetsDirectoryScanner::ScanError)
      expect(File.exist?(indicator_file(rights_package, "progress"))).to be true
      expect(File.exist?(indicator_file(checksum_package, "done"))).to be false
      expect { described_class.perform_scan }.not_to change(BatchProcess, :count)
    end

    it "reports a mets file again once its progress file is a day old" do
      expect { described_class.perform_scan }.to raise_error(MetsDirectoryScanner::ScanError)
      File.utime(Time.now.utc, Time.now.utc - 2.days, indicator_file(rights_package, "progress"))
      expect { described_class.perform_scan }.to raise_error(MetsDirectoryScanner::ScanError, /1 mets file failed to ingest/).and change(BatchProcess, :count).by(1)
    end
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
