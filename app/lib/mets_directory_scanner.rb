# frozen_string_literal: true
require 'find'

# performs scans on directories for XML files and processes them if they are not already done or in progress
class MetsDirectoryScanner
  def self.perform_scan # rubocop:disable Metrics/AbcSize
    MetsDirectoryScanner.scan_directories.each do |directory|
      Dir.glob(File.join(directory, '*/*_mets.xml')) do |path|
        next unless path =~ /.*_mets\.xml$/ && path !~ /.*xslt_result_mets\.xml$/
        check_file(path)
      end
    end
  end

  def self.indicator_file_prefix
    env_info = (ENV['METS_SCAN_LOCK_NAME']) || (ENV['BLACKLIGHT_BASE_URL'] && URI.parse(ENV['BLACKLIGHT_BASE_URL']).host.split('.').first) || 'NO_ENV_NAME'
    "dcs-#{env_info}"
  end

  def self.scan_directories
    scans_by_goobi_mount = ENV['GOOBI_MOUNT'] && [File.join('/', ENV['GOOBI_MOUNT'], 'dcs'), File.join('/', ENV['GOOBI_MOUNT'], 'jss_export')]
    ENV['GOOBI_SCAN_DIRECTORIES']&.split(',') || scans_by_goobi_mount || ['/brbl-dsu/dcs', '/brbl-dsu/jss_export']
  end

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

  def self.process_file(xml_file_path)
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
    rescue => e
      Rails.logger.error("Error processing mets #{xml_file_path} #{e}")
    end
  end
end
