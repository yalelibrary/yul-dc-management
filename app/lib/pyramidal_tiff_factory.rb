# frozen_string_literal: true

# This class takes a child_object's oid, retrieves the access_master for that child object, creates a pyramidal tiff from the access master,
# and saves that pyramidal tiff to an S3 bucket.
class PyramidalTiffFactory
  attr_reader :oid, :access_master_path
  S3 = Aws::S3::Client.new(region: ENV['AWS_DEFAULT_REGION'])

  # This method takes the oid of a child_object and creates a new PyramidalTiffFactory
  def initialize(oid)
    @oid = oid
    @access_master_path = PyramidalTiffFactory.access_master_path(oid)
    @remote_ptiff_path = PyramidalTiffFactory.remote_ptiff_path(oid)
  end

  def self.generate_ptiff_from(oid)
    if ENV['ACCESS_MASTER_SOURCE'] == "S3"
      PyramidalTiffFactory.generate_ptiff_from_s3(oid)
    else
      PyramidalTiffFactory.generate_ptiff_from_local_mount(oid)
    end
  end

  def self.generate_ptiff_from_local_mount(oid)
    ptf = PyramidalTiffFactory.new(oid)
    tiff_input_path = ptf.copy_local_access_master_to_working_directory
    ptf.convert_to_ptiff(tiff_input_path)
    ptf.save_to_s3(File.join(ENV["PTIFF_OUTPUT_DIRECTORY"], File.basename(ptf.access_master_path)))
  end

  def self.generate_ptiff_from_s3(oid)
    ptf = PyramidalTiffFactory.new(oid)
    tiff_input_path = ptf.copy_remote_access_master_to_working_directory
    ptf.convert_to_ptiff(tiff_input_path)
    ptf.save_to_s3(File.join(ENV["PTIFF_OUTPUT_DIRECTORY"], File.basename(ptf.access_master_path)))
  end

  ##
  # We don't know for sure where the access master mount will be, this is a default for local development for now
  def self.access_master_path(oid)
    image_mount = ENV['ACCESS_MASTER_MOUNT'] || "data"
    "#{image_mount}/#{oid}.tif"
  end

  def self.remote_access_master_path(oid)
    image_bucket = "originals"
    "#{image_bucket}/#{oid}.tif"
  end

  def copy_remote_access_master_to_working_directory
    temp_workspace = ENV['TEMP_IMAGE_WORKSPACE'] || "/tmp"
    raise "Expected directory #{temp_workspace} does not exist." unless File.directory?(temp_workspace)
    remote_access_master_path = PyramidalTiffFactory.remote_access_master_path(oid)
    raise "Expected file #{remote_access_master_path} does not exist." unless S3Service.image_exists?(remote_access_master_path)
    temp_file_path = File.join(temp_workspace, File.basename(access_master_path))
    S3Service.download_image(remote_access_master_path, temp_file_path)
    temp_file_path
  end

  ##
  # Create a temp copy of the input file in TEMP_IMAGE_WORKSPACE
  def copy_local_access_master_to_working_directory
    temp_workspace = ENV['TEMP_IMAGE_WORKSPACE'] || "/tmp"
    raise "Expected directory #{temp_workspace} does not exist." unless File.directory?(temp_workspace)
    raise "Expected file #{access_master_path} does not exist." unless File.exist?(access_master_path)
    FileUtils.cp(access_master_path, temp_workspace)
    temp_file_path = File.join(temp_workspace, File.basename(access_master_path))
    return temp_file_path unless compare_checksums(access_master_path, temp_file_path)
  end

  def convert_to_ptiff(tiff_input_path)
    ptiff_output_path = File.join(ENV["PTIFF_OUTPUT_DIRECTORY"], File.basename(access_master_path))
    _stdout, _stderr, status = Open3.capture3("app/lib/tiff_to_pyramid.bash #{Dir.mktmpdir} #{tiff_input_path} #{ptiff_output_path}")
    raise "Conversion script exited with error code #{status.exitstatus}" if status.exitstatus != 0
    # Preparation for being able to save the width and height to the ChildObject, just not quite ready to implement yet
    # width = stdout.match(/Pyramid width: (\d*)/).captures[0]
    # height = stdout.match(/Pyramid height: (\d*)/).captures[0]
  end

  def self.remote_ptiff_path(oid)
    File.join("ptiffs", File.basename(access_master_path(oid)))
  end

  def save_to_s3(ptiff_output_path)
    S3Service.upload_image(ptiff_output_path, @remote_ptiff_path)
  end

  def compare_checksums(access_master_path, temp_file_path)
    access_master_checksum = Digest::SHA256.file(access_master_path)
    temp_file_checksum = Digest::SHA256.file(temp_file_path)
    raise "Checksum failed. Should be: #{access_master_checksum}" unless access_master_checksum == temp_file_checksum
  end
end
