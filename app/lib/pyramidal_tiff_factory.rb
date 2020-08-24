# frozen_string_literal: true
require 'aws-sdk-s3'
require 'digest'
require 'English'

# 0. Locate access_master
# 1. Copy access_master to local workspace
# 2. Create ptiff from local file using tiff_to_pyramid.bash
# 3. Save ptiff to S3
# 4. Remove local copy

class PyramidalTiffFactory
  S3 = Aws::S3::Client.new(region: ENV['AWS_DEFAULT_REGION'])


  ##
  # Create a local copy of the input file in TEMP_IMAGE_WORKSPACE
  def self.make_tempfile(input)
    raise "Expected directory #{ENV['TEMP_IMAGE_WORKSPACE']} does not exist." unless File.directory?(ENV["TEMP_IMAGE_WORKSPACE"])
    raise "Expected file #{input} does not exist." unless File.exists?(input)
    FileUtils.cp(input, ENV["TEMP_IMAGE_WORKSPACE"])
  end

  def self.convert(cksum, bucket, input)
    temp_in = make_tempfile(input)
    # S3.get_object(bucket: bucket, key: input) do |chunk|
    #   temp_in.write chunk
    # end

    check = Digest::SHA256.file(temp_in)
    raise "Checksum failed. Should be: #{check}" unless check == cksum

    temp_out = Tempfile.new
    STDOUT.puts `lib/tiff_to_pyramid.bash #{Dir.mktmpdir} #{temp_in.path} #{temp_out.path}`

    raise "Conversion script exited with error code #{$CHILD_STATUS.exitstatus}" if $CHILD_STATUS.exitstatus != 0

    out_key = "ptiffs/#{input.split('/').last}"

    File.open(temp_out, 'rb') do |f|
      S3.put_object(bucket: bucket, key: out_key, body: f)
    end
    "s3://#{bucket}/#{out_key}"
  end
end
