# frozen_string_literal: true

class S3Service
  @client ||= Aws::S3::Client.new

  def self.upload(file_path, data)
    @client.put_object(
      body: data,
      bucket: ENV['SAMPLE_BUCKET'],
      key: file_path
    )
  end

  # Returns the response body text
  def self.download(file_path)
    resp = @client.get_object(bucket: ENV['SAMPLE_BUCKET'], key: file_path)
    resp.body&.read
  rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::NotFound, Aws::S3::Errors::BadRequest
    nil
  end

  # Takes a remote S3 bucket path and writes the retrieved image to a local path.
  # It downloads it in chunks because images are very large.
  def self.download_image(remote_path, local_path)
    object = Aws::S3::Object.new(bucket_name: ENV['S3_SOURCE_BUCKET_NAME'], key: remote_path)
    object.download_file(local_path, destination: local_path)
  end

  def self.upload_image(local_path, remote_path)
    File.open(local_path, 'r') do |f|
      @client.put_object(
        bucket: ENV['S3_SOURCE_BUCKET_NAME'],
        key: remote_path,
        body: f
      )
    end
  end

  def self.s3_exists?(remote_path, bucket = ENV['S3_SOURCE_BUCKET_NAME'])
    object = Aws::S3::Object.new(bucket_name: bucket, key: remote_path)
    object.exists?
  end
end
