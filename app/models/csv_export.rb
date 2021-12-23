# frozen_string_literal: true

# frozen_string_literal

class CsvExport
  def initialize(csv, batch_process)
    @csv = csv
    @batch_process = batch_process
  end

  def self.presigned_url(export_path, seconds, bucket = ENV['S3_SOURCE_BUCKET_NAME'])
    return export_path unless bucket
    object = Aws::S3::Object.new(bucket_name: bucket, key: export_path)
    object.presigned_url('get', expires_in: seconds, response_content_disposition: 'attachment')
  end

  def fetch
    S3Service.download(export_path)
  end

  def save
    S3Service.upload_if_changed(export_path, @csv)
  end

  def export_path
    @export_path ||= "/batch/job/#{@batch_process.id}/#{@batch_process.file_name}"
  end
end
