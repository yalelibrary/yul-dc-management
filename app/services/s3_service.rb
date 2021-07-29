# frozen_string_literal: true

class S3Service
  @client ||= Aws::S3::Client.new # for debugging add (http_wire_trace: true)

  def self.upload(file_path, data)
    @client.put_object(
      body: data,
      bucket: ENV['SAMPLE_BUCKET'],
      key: file_path
    )
  end

  def self.delete(file_path)
    @client.delete_object(
      # bucket issue?
      bucket: ENV['S3_SOURCE_BUCKET_NAME'],
      key: file_path
    )
  end

  def self.upload_if_changed(file_path, data, bucket = ENV['SAMPLE_BUCKET'])
    return true if checksum_matches?(file_path, bucket, data)
    status = @client.put_object(
      body: data,
      bucket: bucket,
      key: file_path
    )
    status.successful?
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
  def self.download_image(remote_path, local_path, bucket = ENV['S3_SOURCE_BUCKET_NAME'])
    object = Aws::S3::Object.new(bucket_name: bucket, key: remote_path)
    object.download_file(local_path, destination: local_path)
  end

  def self.upload_image(local_path, remote_path, content_type, metadata)
    File.open(local_path, 'r') do |f|
      @client.put_object(
        bucket: ENV['S3_SOURCE_BUCKET_NAME'],
        key: remote_path,
        body: f,
        content_type: content_type,
        metadata: metadata
      )
    end
  end

  # Returns String which is a pre-signed URL that a client can use to access the
  # object from S3 without needing other credentials.
  def self.presigned_url(remote_path, seconds, bucket = ENV['S3_SOURCE_BUCKET_NAME'])
    return remote_path unless bucket
    object = Aws::S3::Object.new(bucket_name: bucket, key: remote_path)
    object.presigned_url('get', expires_in: seconds)
  end

  def self.remote_metadata(remote_path, bucket = ENV['S3_SOURCE_BUCKET_NAME'])
    object = Aws::S3::Object.new(bucket_name: bucket, key: remote_path)
    return false unless object.exists?
    object.metadata.symbolize_keys
  end

  def self.checksum_matches?(remote_path, bucket, data)
    etag = S3Service.etag(remote_path, bucket)
    return false unless etag
    md5 = "\"#{Digest::MD5.hexdigest(data)}\""
    md5 == etag
  end

  def self.etag(remote_path, bucket = ENV['SAMPLE_BUCKET'])
    object = Aws::S3::Object.new(bucket_name: bucket, key: remote_path)
    return nil unless object.exists?
    object.etag
  end

  def self.s3_exists?(remote_path, bucket = ENV['S3_SOURCE_BUCKET_NAME'])
    object = Aws::S3::Object.new(bucket_name: bucket, key: remote_path)
    object.exists?
  end

  def self.full_text_exists?(remote_path, bucket = ENV['OCR_DOWNLOAD_BUCKET'])
    object = Aws::S3::Object.new(bucket_name: bucket, key: remote_path)
    begin
      return true if object.exists? && object.content_type == 'text/plain'
    rescue Aws::S3::Errors::Forbidden
      false
    end
    false
  end

  def self.download_full_text(file_path, bucket = ENV['OCR_DOWNLOAD_BUCKET'])
    resp = @client.get_object(bucket: bucket, key: file_path)
    resp.body&.read
  rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::NotFound, Aws::S3::Errors::BadRequest
    nil
  end
end
