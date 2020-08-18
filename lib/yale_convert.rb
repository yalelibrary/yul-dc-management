# frozen_string_literal: true
require 'aws-sdk-s3'
require 'digest'
require 'English'

class YaleConvert
  S3 = Aws::S3::Client.new(region: ENV['AWS_DEFAULT_REGION'])

  def self.convert(cksum, bucket, input)
    temp_in = Tempfile.new(binmode: true)
    S3.get_object(bucket: bucket, key: input) do |chunk|
      temp_in.write chunk
    end

    check = Digest::SHA256.file(temp_in)
    raise "Checksum failed. Should be: #{check}" unless check == cksum

    temp_out = Tempfile.new
    STDOUT.puts `lib/nga.sh #{Dir.mktmpdir} #{temp_in.path} #{temp_out.path}`

    raise "Conversion script exited with error code #{$CHILD_STATUS.exitstatus}" if $CHILD_STATUS.exitstatus != 0

    out_key = "ptiffs/#{input.split('/').last}"

    File.open(temp_out, 'r') do |f|
      S3.put_object(bucket: bucket, key: out_key, body: f)
    end
    "s3://#{bucket}/#{out_key}"
  end
end
