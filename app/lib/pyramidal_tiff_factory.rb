# frozen_string_literal: true

# This class takes a child_object's oid, retrieves the access_master for that child object, creates a pyramidal tiff from the access master,
# and saves that pyramidal tiff to an S3 bucket.
class PyramidalTiffFactory
  attr_reader :oid
  S3 = Aws::S3::Client.new(region: ENV['AWS_DEFAULT_REGION'])

  # This method takes the oid of a child_object and creates a new PyramidalTiffFactory
  def initialize(oid)
    @oid = oid
  end

  def self.generate_ptiff_from(oid)
    ptf = PyramidalTiffFactory.new(oid)
    tiff_input_path = ptf.copy_access_master_to_working_directory
    ptf.convert_to_ptiff(tiff_input_path)
    ptf.save_to_s3(File.join(ENV["PTIFF_OUTPUT_DIRECTORY"], File.basename(ptf.access_master_path)))
  end

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
    return temp_file_path unless compare_checksums(access_master_path, temp_file_path)
  end

  def convert_to_ptiff(tiff_input_path)
    ptiff_output_path = File.join(ENV["PTIFF_OUTPUT_DIRECTORY"], File.basename(access_master_path))
    stdout, stderr, status = Open3.capture3("app/lib/tiff_to_pyramid.bash #{Dir.mktmpdir} #{tiff_input_path} #{ptiff_output_path}")
    raise "Conversion script exited with error code #{status.exitstatus}" if status.exitstatus != 0
    # width = stdout.match(/Pyramid width: (\d*)/).captures[0]
    # height = stdout.match(/Pyramid height: (\d*)/).captures[0]
  end

  def save_to_s3(ptiff_output_path)
    remote_path = File.join("ptiffs", File.basename(access_master_path))
    S3Service.upload_image(ptiff_output_path, remote_path)
  end

  def compare_checksums(access_master_path, temp_file_path)
    access_master_checksum = Digest::SHA256.file(access_master_path)
    temp_file_checksum = Digest::SHA256.file(temp_file_path)
    raise "Checksum failed. Should be: #{access_master_checksum}" unless access_master_checksum == temp_file_checksum
  end
end
