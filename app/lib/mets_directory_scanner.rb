# frozen_string_literal: true
require 'find'
require 'fcntl'

# performs scans on directories for XML files and processes them if they are not already done or in progress
class MetsDirectoryScanner
  # raised at the end of a scan so failed mets files show in GoodJob
  class ScanError < StandardError; end

  def self.perform_scan # rubocop:disable Metrics/AbcSize
    failures = []
    MetsDirectoryScanner.scan_directories.each do |directory|
      Dir.glob(File.join(directory, '*/*_mets.xml')) do |path|
        next unless path =~ /.*_mets\.xml$/ && path !~ /.*xslt_result_mets\.xml$/
        failure = check_file(path)
        failures << failure if failure
      end
    end
    raise ScanError, "#{failures.count} mets #{'file'.pluralize(failures.count)} failed to ingest:\n#{failures.join("\n")}" if failures.any?
  end

  def self.indicator_file_prefix
    env_info = (ENV['METS_SCAN_LOCK_NAME']) || (ENV['BLACKLIGHT_BASE_URL'] && URI.parse(ENV['BLACKLIGHT_BASE_URL']).host.split('.').first) || 'NO_ENV_NAME'
    "dcs-#{env_info}"
  end

  def self.scan_directories
    scans_by_goobi_mount = ENV['GOOBI_MOUNT'] && [File.join('/', ENV['GOOBI_MOUNT'], 'dcs'), File.join('/', ENV['GOOBI_MOUNT'], 'jss_export')]
    ENV['GOOBI_SCAN_DIRECTORIES']&.split(',') || scans_by_goobi_mount || ['/brbl-dsu/dcs', '/brbl-dsu/jss_export']
  end

  # returns an error message if the mets file failed to process, otherwise nil
  def self.check_file(path)
    is_done = File.exist?(File.join(File.dirname(path), "#{indicator_file_prefix}.done"))
    progress_file = File.join(File.dirname(path), "#{indicator_file_prefix}.progress")
    File.delete(progress_file) if File.exist?(progress_file) && File.mtime(progress_file) < (Time.now.utc - 1.day)
    is_in_progress = File.exist?(progress_file)
    begin
      unless is_done || is_in_progress
        #  The following will fail if file is not created by this call because of Fcntl::O_EXCL option:
        IO.sysopen(progress_file, Fcntl::O_WRONLY | Fcntl::O_EXCL | Fcntl::O_CREAT)
        #  If we get here, the done file doesn't exist, and we just created the progress file....so we are ready to go
        process_file path
      end
    rescue Errno::EEXIST # rubocop:disable Lint/HandleExceptions
      # If we get here it means some other instance of a scanner just put in a progress file,
      # it's ok to let them handle it
    end
  end

  # returns an error message if the mets file failed to process, otherwise nil
  def self.process_file(xml_file_path) # rubocop:disable Metrics/MethodLength
    file = ActionDispatch::Http::UploadedFile.new(
      filename: File.basename(xml_file_path),
      type: 'text/xml',
      tempfile: File.new(xml_file_path.to_s)
    )
    begin
      batch_process = BatchProcess.new(batch_action: 'create parent objects', user: User.system_user, file: file)
      if batch_process.save!
        # Jobs have been kicked off and batch job has been created, so we'll mark it as done and
        # check for errors in management.
        # If we wait to create the done file until it is successful through the entire process,
        # we may pile up failed jobs if there's something wrong with the mets that makes it error out on
        # some step of the import.
        # The process will restart using delayed jobs without kicking it off again from a scan.
        # If we need to force a retry, we will manually delete the done file for a mets directory after the problem
        # is corrected.
        done_file = File.join(File.dirname(xml_file_path), "#{indicator_file_prefix}.done")
        progress_file = File.join(File.dirname(xml_file_path), "#{indicator_file_prefix}.progress")
        File.new(done_file, "w")
        File.delete(progress_file) if File.exist?(progress_file)
      end
      nil
    # the progress file is left in place on failure, so the mets file will be retried once it is a day old
    rescue ActiveRecord::RecordInvalid => e
      report_invalid_mets(xml_file_path, batch_process, e)
    rescue => e
      Rails.logger.error("Error processing mets #{xml_file_path} #{e}")
      "#{xml_file_path}: #{e.message}"
    end
  end

  # creates a failed batch process for a mets file that fails validation
  def self.report_invalid_mets(xml_file_path, batch_process, error)
    Rails.logger.error("Error processing mets #{xml_file_path} #{error}")
    message = invalid_mets_message(batch_process.mets_doc, error)
    failed_batch_process = BatchProcess.create!(batch_action: 'create parent objects', user: User.system_user, file_name: File.basename(xml_file_path),
                                                oid: batch_process.mets_doc&.oid.presence&.to_i)
    failed_batch_process.batch_processing_event(message, 'failed')
    "#{xml_file_path}: #{error.message}"
  end

  def self.invalid_mets_message(mets_doc, error)
    mets_doc&.valid_mets?
    "Ingest failed. #{error.message}"
  rescue MetsDocument::ImageError
    SetupMetadataJob::GOOBI_IMAGES_MESSAGE
  rescue StandardError => e
    "Ingest failed. #{e.message}"
  end
end
