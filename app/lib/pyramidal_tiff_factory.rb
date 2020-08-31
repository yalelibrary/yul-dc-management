# frozen_string_literal: true

# This class takes a child_object's oid, retrieves the access_master for that child object, creates a pyramidal tiff from the access master,
# and saves that pyramidal tiff to an S3 bucket.
class PyramidalTiffFactory
  attr_reader :child_object, :access_master_path, :remote_ptiff_path, :errors, :oid, :temp_workspace, :remote_access_master_path

  # This method takes the oid of a child_object and creates a new PyramidalTiffFactory
  def initialize(child_object)
    @oid = child_object.oid.to_s
    @temp_workspace = ENV['TEMP_IMAGE_WORKSPACE'] || "/tmp"
    @remote_access_master_path = PyramidalTiffFactory.remote_access_master_path(oid)
    @access_master_path = PyramidalTiffFactory.access_master_path(oid)
    @remote_ptiff_path = PyramidalTiffFactory.remote_ptiff_path(oid)
    @errors = ActiveModel::Errors.new(self)
  end

  def valid?(child_object)
    raise "Expected directory #{temp_workspace} does not exist." unless File.directory?(temp_workspace)
    ptiff_info = { oid: oid.to_s }
    # cannot convert to PTIFF if we can't find the original
    return false unless original_file_exists?
    # do not do the image conversion if there is already a PTIFF on S3
    if S3Service.image_exists?(child_object.remote_ptiff_path)
      Rails.logger.info("PTIFF exists on S3, not converting: #{ptiff_info.to_json}")
      false
    else
      true
    end
  end

  def original_file_exists?
    if ENV['ACCESS_MASTER_MOUNT'] == "s3"
      image_exists = S3Service.image_exists?(remote_access_master_path)
      errors.add(:access_master_not_found, "Expected file #{remote_access_master_path} not found.") unless image_exists
    else
      image_exists = File.exist?(access_master_path)
      errors.add(:access_master_not_found, "Expected file #{access_master_path} not found.") unless image_exists
    end
    image_exists
  end

  def self.generate_ptiff_from(child_object)
    ptf = PyramidalTiffFactory.new(child_object)
    return false unless ptf.valid?(child_object)
    tiff_input_path = ptf.copy_access_master_to_working_directory
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

  ##
  # Create a temp copy of the input file in TEMP_IMAGE_WORKSPACE
  def copy_access_master_to_working_directory
    temp_file_path = File.join(temp_workspace, File.basename(access_master_path))
    if ENV['ACCESS_MASTER_MOUNT'] == "s3"
      download = S3Service.download_image(remote_access_master_path, temp_file_path)
      temp_file_path if download
    else
      FileUtils.cp(access_master_path, temp_workspace)
      return temp_file_path unless compare_checksums(access_master_path, temp_file_path)
    end
  end

  def convert_to_ptiff(tiff_input_path)
    ptiff_output_path = File.join(ENV["PTIFF_OUTPUT_DIRECTORY"], File.basename(access_master_path))
    _stdout, _stderr, status = Open3.capture3("app/lib/tiff_to_pyramid.bash #{Dir.mktmpdir} #{tiff_input_path} #{ptiff_output_path}")
    errors.add("Conversion script exited with error code #{status.exitstatus}") if status.exitstatus != 0
    # raise "Conversion script exited with error code #{status.exitstatus}" if status.exitstatus != 0
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
    checksum_info = { oid: oid.to_s, access_master_path: access_master_path.to_s, temp_file_path: temp_file_path.to_s }
    raise "File copy unsuccessful, checksums do not match: #{checksum_info.to_json}" unless access_master_checksum == temp_file_checksum
  end
end
