# frozen_string_literal: true
require 'find'

# performs scans on directories for XML files and processes them if they are not already done or in progress
class MetsDirectoryScanner
  def self.perform_scan
    Find.find(MetsDirectoryScanner.root_directory) do |path|
      next unless path =~ /.*\.xml$/
      is_done = File.exist?(File.join(File.dirname(path), "#{indicator_file_prefix}.done"))
      begin
        unless is_done
          progress_file = File.join(File.dirname(path), "#{indicator_file_prefix}.progress")
          File.delete(progress_file) if File.exist?(progress_file) && File.mtime(progress_file) < (Time.now.utc - 1.day)
          #  The following will fail if file is not created by this call:
          IO.sysopen(progress_file, Fcntl::O_WRONLY | Fcntl::O_EXCL | Fcntl::O_CREAT)
          #  If we get here, the done file doesn't exist, and we just created the progress file....so we are ready to go
          process_file path
        end
      rescue Errno::EEXIST # rubocop:disable Lint/HandleExceptions
        # we get here is means some other instance of a scanner just put in a progress file,
        # it's ok to let them handle it
      end
    end
  end

  def self.process_file(xml_file_path)
    file = ActionDispatch::Http::UploadedFile.new(
      filename: File.basename(xml_file_path),
      type: 'text/xml',
      tempfile: File.new(xml_file_path.to_s)
    )
    begin
      batch_process = BatchProcess.new(batch_action: 'create parent objects')
      # set file with setter to trigger reading
      batch_process.file = file
      batch_process.save!
    rescue => e
      Rails.logger.error("Error processing mets #{xml_file_path} #{e}")
    end
  end

  def self.indicator_file_prefix
    ENV['CLUSTER_NAME'] || 'NO_ENV_NAME'
  end

  def self.root_directory
    ENV['GOOBI_MOUNT'] || '/brbl-dsu'
  end
end
