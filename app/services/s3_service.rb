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
  rescue Aws::S3::Errors::NoSuchKey, Aws::S3::Errors::NotFound
    nil
  end
end
