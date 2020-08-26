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

  def self.download(file_path)
    resp = @client.get_object(bucket: ENV['SAMPLE_BUCKET'], key: file_path)
    resp.body&.read
  rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::NotFound, Aws::S3::Errors::BadRequest
    nil
  end

  def self.download_image(remote_path, local_path)
    @client.get_object(bucket: ENV["S3_SOURCE_BUCKET_NAME"], key: remote_path) do |chunk|
      path = Pathname.new(local_path)
      path.binwrite chunk
    end
  end
end
