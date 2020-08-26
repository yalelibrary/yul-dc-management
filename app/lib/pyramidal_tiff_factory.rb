# frozen_string_literal: true
require 'aws-sdk-s3'
require 'digest'
require 'English'

# 0. Locate access_master
# 1. Copy access_master to local workspace
# 2. Create ptiff from local file using tiff_to_pyramid.bash
# 3. Save ptiff to S3
# 4. Remove local copy

# child_object = ChildObject.something
# child_object.oid
# ptf = PyramidalTiffFactory.new(child_object.oid)
# ptf.ptiff_already_exists?
# ptf.make_ptiff

# This class takes a child_object's oid, retrieves the access_master for that child object, creates a pyramidal tiff from the access master,
# and saves that pyramidal tiff to an S3 bucket.
class PyramidalTiffFactory
  attr_reader :oid
  S3 = Aws::S3::Client.new(region: ENV['AWS_DEFAULT_REGION'])

  # This method takes the oid of a child_object and creates a new PyramidalTiffFactory
  def initialize(oid)
    @oid = oid
  end

  def self.generate_ptiff(oid); end

  def access_master_path
    "#{ENV['ACCESS_MASTER_MOUNT']}/#{oid}.tif"
  end

  ##
  # Create a local copy of the input file in TEMP_IMAGE_WORKSPACE
  def copy_access_master_to_working_directory
    raise "Expected directory #{ENV['TEMP_IMAGE_WORKSPACE']} does not exist." unless File.directory?(ENV["TEMP_IMAGE_WORKSPACE"])
    raise "Expected file #{access_master_path} does not exist." unless File.exist?(access_master_path)
    FileUtils.cp(access_master_path, ENV["TEMP_IMAGE_WORKSPACE"])
    temp_file_path = File.join(ENV["TEMP_IMAGE_WORKSPACE"], File.basename(access_master_path))
    temp_file_path
  end

  def convert_to_ptiff
    tiff_input_file = copy_access_master_to_working_directory
    ptiff_output_file = File.join(ENV["PTIFF_OUTPUT_DIRECTORY"], File.basename(access_master_path))
    STDOUT.puts `app/lib/tiff_to_pyramid.bash #{Dir.mktmpdir} #{tiff_input_file} #{ptiff_output_file}`
  end

  def save_to_s3
    File.open(temp_out, 'rb') do |f|
      S3.put_object(bucket: bucket, key: out_key, body: f)
    end
    "s3://#{bucket}/#{out_key}"
  end

  def self.convert(cksum, bucket, input)
    temp_in = copy_access_master_to_working_directory

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
