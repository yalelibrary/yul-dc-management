# frozen_string_literal: true

# This class takes a child_object's oid, retrieves the access_primary for that child object, creates a pyramidal tiff from the access primary,
# and saves that pyramidal tiff to an S3 bucket.
class PyramidalTiff
  include ActiveModel::Validations

  attr_accessor :child_object, :conversion_information, :force_update
  validate :verify_and_generate
  delegate :access_primary_path, :mets_access_primary_path, :remote_access_primary_path, :remote_ptiff_path, :oid, to: :child_object

  # This method takes the oid of a child_object and creates a new PyramidalTiff
  def initialize(child_object)
    @child_object = child_object
    @conversion_information = {}
  end

  def generate_ptiff
    # this adds the height and width to the object
    Dir.mktmpdir do |swing_tmpdir|
      tiff_input_path = copy_access_primary_to_working_directory(swing_tmpdir)
      Dir.mktmpdir do |ptiff_tmpdir|
        @conversion_information = convert_to_ptiff(tiff_input_path, ptiff_tmpdir)
        save_to_s3(File.join(ptiff_tmpdir, File.basename(access_primary_path)), @conversion_information) unless @conversion_information.empty?
      end
    end
    conversion_information
  end

  def height_and_width?
    child_object.height && child_object.width
  end

  def verify_and_generate
    ptiff_info = { oid: oid.to_s }
    file_on_s3 = S3Service.s3_exists?(child_object.remote_ptiff_path)
    child_object.check_for_size_and_file if !height_and_width? && file_on_s3
    # do not do the image conversion if there is already a PTIFF on S3
    if height_and_width? && !force_update && file_on_s3
      child_object.processing_event("PTIFF exists on S3, not converting: #{ptiff_info.to_json}", 'ptiff-ready-skipped')
      true
    else
      # cannot convert to PTIFF if we can't find the original
      return false unless original_file_exists? # this returns true
      generate_ptiff
    end
  end

  # rubocop:disable Metrics/PerceivedComplexity
  def original_file_exists?
    if child_object.parent_object&.from_mets == true
      image_exists = File.exist?(mets_access_primary_path) || File.exist?(mets_access_primary_path.gsub('.tif', '.TIF').gsub('.jpg', '.JPG'))
      errors.add(:base, "Expected file #{mets_access_primary_path} on mets not found.") unless image_exists
    elsif ENV['ACCESS_PRIMARY_MOUNT'] == "s3"
      image_exists = S3Service.s3_exists?(remote_access_primary_path)
      errors.add(:base, "Expected file #{remote_access_primary_path} on S3 not found.") unless image_exists
    else
      image_exists = File.exist?(access_primary_path)
      errors.add(:base, "Expected file #{access_primary_path} on shares at Yale not found.") unless image_exists
    end
    image_exists
  end
  # rubocop:enable Metrics/PerceivedComplexity

  ##
  # Create a temp copy of the input file in TEMP_IMAGE_WORKSPACE
  # @param [String] tmpdir - the tmpdir location where the file should be written
  # @return [String] the full path where the file was downloaded
  def copy_access_primary_to_working_directory(tmpdir)
    temp_file_path = File.join(tmpdir, File.basename(access_primary_path))
    if ENV['ACCESS_PRIMARY_MOUNT'] == "s3"
      download = S3Service.download_image(remote_access_primary_path, temp_file_path)
      if download
        child_object.processing_event("Access primary retrieved from S3", 'access-primary')
        temp_file_path
      end
    else
      FileUtils.cp(access_primary_path, tmpdir)
      child_object.processing_event("Access primary retrieved from file system", 'access-primary')
      temp_file_path
    end
  end

  def build_command(ptiff_tmpdir, tiff_input_path, ptiff_output_path)
    "app/lib/tiff_to_pyramid.bash #{ptiff_tmpdir} #{tiff_input_path} #{ptiff_output_path}"
  end

  def convert_to_ptiff(tiff_input_path, ptiff_tmpdir)
    ptiff_output_path = File.join(ptiff_tmpdir, File.basename(access_primary_path))
    stdout, stderr, status = Open3.capture3(build_command(ptiff_tmpdir, tiff_input_path, ptiff_output_path))
    errors.add(:base, "Conversion script exited with error code #{status.exitstatus}. ---\n#{stdout}---\n#{stderr}") if status.exitstatus != 0
    return {} if status.exitstatus != 0
    width = stdout.match(/Pyramid width: (\d*)/)&.captures&.[](0)
    height = stdout.match(/Pyramid height: (\d*)/)&.captures&.[](0)
    child_object.processing_event("PTIFF created #{width} x #{height}", 'ptiff-generated')
    { width: width, height: height }
  end

  def save_to_s3(ptiff_output_path, conversion_information)
    metadata = { 'width': conversion_information[:width].to_s, 'height': conversion_information[:height].to_s }
    S3Service.upload_image(ptiff_output_path, remote_ptiff_path, "image/tiff", metadata)
  end
end
