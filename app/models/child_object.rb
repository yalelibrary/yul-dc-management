# frozen_string_literal: true

#
# ChildObjects are _deleted_ when parents are destroyed; expect that ChildObjects will be
# deleted _without_ any destroy hooks called.
#

# rubocop:disable ClassLength
class ChildObject < ApplicationRecord
  # rubocop:enable ClassLength
  has_paper_trail
  include Statable
  include Delayable
  include SolrIndexable
  belongs_to :parent_object, foreign_key: 'parent_object_oid', class_name: "ParentObject"
  has_many :batch_connections, as: :connectable
  has_many :batch_processes, through: :batch_connections
  has_one :admin_set, through: :parent_object
  self.primary_key = 'oid'
  paginates_per 50
  attr_accessor :current_batch_process
  attr_accessor :current_batch_connection

  # Does not get called because we use upsert to create children
  # before_create :check_for_size_and_file

  # Queue parent manifest update when child object is successfully updated
  after_update :queue_parent_manifest_update

  # Options from iiif presentation api 2.1 - see https://iiif.io/api/presentation/2.1/#viewinghint
  # These are added to the manifest on the canvas level
  def self.viewing_hints
    [nil, "non-paged", "facing-pages"]
  end

  def start_states
    ["ptiff-queued", "processing-queued"]
  end

  def finished_states
    ['deleted', 'ptiff-ready-skipped', 'ptiff-ready', 'reassociate-complete', 'review-complete', 'update-complete']
  end

  def check_for_size_and_file
    width_and_height(remote_metadata)
  end

  def remote_ptiff_exists?
    remote_metadata
  end

  def remote_metadata
    S3Service.remote_metadata(remote_ptiff_path)
  end

  def remote_ocr
    S3Service.full_text_exists?(remote_ocr_path)
  end

  def access_primary_path
    return @access_primary_path if @access_primary_path
    image_mount = ENV['ACCESS_PRIMARY_MOUNT'] || "data"
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    directory = format("%02d", pairtree_path.first)
    @access_primary_path = File.join(image_mount, directory, pairtree_path, "#{oid}.tif")
  end

  # rubocop:disable  Metrics/MethodLength
  # rubocop:disable  Layout/LineLength
  def copy_to_access_primary_pairtree
    # Don't copy over existing access primaries if they already exist
    # TODO: Determine what happens if it's an intentional re-shoot of a child image
    #  1. How is that signalled? (ensure that it's an intentional re-shoot, not accidental duplication)
    #  2. We assume that there is only one access primary at a time - BUT we only have one access primary pair-tree
    #     across *all* environments (no separation of dev, test, uat, production)
    #     how do we ensure we don't accidentally overwrite something we want to keep?
    if access_primary_exists? && checksum_matches?
      processing_event("Not copied from Goobi package to access primary pair-tree, already exists", 'access-primary-exists')
      return true
    end
    unless mets_access_primary_checksum_matches?
      processing_event("Original Copy of checksum does not match", 'failed')
      false
    end
    image_mount = ENV['ACCESS_PRIMARY_MOUNT'] || "data"
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    directory = format("%02d", pairtree_path.first)
    # Create path to access primary if it doesn't exist
    FileUtils.mkdir_p(File.join(image_mount, directory, pairtree_path))
    File.exist?(mets_access_primary_path) ? FileUtils.cp(mets_access_primary_path, access_primary_path) : FileUtils.cp(mets_access_primary_path.gsub('.tif', '.TIF').gsub('.jpg', '.JPG'), access_primary_path)
    if checksum_matches?
      processing_event("Copied from Goobi package to access primary pair-tree", 'goobi-copied')
      true
    else
      processing_event("Copy from Goobi to access primary failed checksum check", 'failed')
      false
    end
  end
  # rubocop:enable  Metrics/MethodLength
  # rubocop:enable  Layout/LineLength

  def checksum_matches?
    # preservica or manually updated by user
    if sha512_checksum.present?
      sha512_checksum == access_sha512_checksum
    # goobi
    elsif checksum.present?
      checksum == Digest::SHA1.file(access_primary_path).to_s
    # ladybird
    elsif sha256_checksum.present?
      sha256_checksum == Digest::SHA256.file(access_primary_path).to_s
    # ladybird
    elsif md5_checksum.present?
      md5_checksum == Digest::MD5.file(access_primary_path).to_s
    else
      false
    end
  end

  def mets_access_primary_checksum_matches?
    mets_primary_checksum = Digest::SHA1.file(mets_access_primary_path).to_s
    checksum == mets_primary_checksum
  end

  def access_primary_exists?
    File.exist?(access_primary_path)
  end

  def access_sha512_checksum
    Digest::SHA512.file(access_primary_path).to_s
  end

  def access_file_size
    File.exist?(access_primary_path) ? File&.size(access_primary_path) : nil
  end

  def remote_access_primary_path
    return @remote_access_primary_path if @remote_access_primary_path
    image_bucket = "originals"
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    @remote_access_primary_path = File.join(image_bucket, pairtree_path, "#{oid}.tif")
  end

  def remote_ptiff_path
    return @remote_ptiff_path if @remote_ptiff_path
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    @remote_ptiff_path = File.join("ptiffs", pairtree_path, File.basename(access_primary_path))
  end

  def remote_ocr_path
    return @remote_ocr_path if @remote_ocr_path
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    @remote_ocr_path = File.join('fulltext', pairtree_path, "#{oid}.txt")
  end

  def remote_ocr_exists?
    return @remote_ocr_exists if @remote_ocr_exists
    @remote_ocr_exists = ChildObject.remote_ocr_exists?(oid)
  end

  def self.remote_ocr_exists?(oid)
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    remote_ocr_path = File.join('fulltext', pairtree_path, "#{oid}.txt")
    S3Service.full_text_exists?(remote_ocr_path)
  end

  def pyramidal_tiff
    @pyramidal_tiff ||= PyramidalTiff.new(self)
  end

  def thumbnail_url
    "#{IiifPresentationV3.new(parent_object).image_service_url(oid)}/full/!200,200/0/default.jpg"
  end

  def width_and_height(size)
    return unless size.present? && size[:width].to_i.positive? && size[:height].to_i.positive?
    self.width = size[:width].to_i
    self.height = size[:height].to_i
    self.ptiff_conversion_at = Time.zone.now if remote_ptiff_exists?
    size
  end

  # rubocop:disable Layout/LineLength
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  def save_image_metadata
    begin
      cmd = "exiftool -s #{access_primary_path}"
      stdout, stderr, status = Open3.capture3(cmd)
    rescue stderr
      # rubocop:disable Layout/LineLength
      parent_object&.processing_event("The child object's image file could not be read. Please contact the Technical Lead for Digital Collections for assistance. ------------ Message from System: Child Object #{oid} failed to gather technical image metadata due to #{stderr} and exited with status: #{status}.", "failed")
      processing_event("The child object's image file could not be read. Please contact the Technical Lead for Digital Collections for assistance. ------------ Message from System: Child Object #{oid} failed to gather technical image metadata due to #{stderr} and exited with status: #{status}.", "failed")
      # rubocop:enable Layout/LineLength
    end
    formatted_stdout = stdout.split(/\n/).map { |a| a.split('  : ') }.map { |a| [a.first.strip, a.last] }.to_h
    self.x_resolution = formatted_stdout["XResolution"].presence || formatted_stdout["WidthResolution"]
    self.y_resolution = formatted_stdout["YResolution"].presence || formatted_stdout["HeightResolution"]
    # rubocop:disable Layout/LineLength
    self.resolution_unit = formatted_stdout["ResolutionUnit"].presence || formatted_stdout["FocalPlaneResolutionUnit"].presence || formatted_stdout["ResolutionXUnit"].presence || formatted_stdout["ResolutionXLengthUnit"]
    # rubocop:enable Layout/LineLength
    self.color_space = formatted_stdout["ColorSpaceData"].presence || formatted_stdout["ColorSpace"]
    self.compression = formatted_stdout["Compression"]
    self.creator = formatted_stdout["Artist"].presence || formatted_stdout["XPAuthor"]
    self.date_and_time_captured = formatted_stdout["CreateDate"].presence || formatted_stdout["DateTime"].presence || formatted_stdout["DateTimeDigitized"]
    self.make = formatted_stdout["Make"]
    self.model = formatted_stdout["Model"].presence || formatted_stdout["Model2"].presence || formatted_stdout["UniqueCameraModel"].presence || formatted_stdout["LocalizedCameraModel"]
    save!
  end
  # rubocop:enable Layout/LineLength
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  # TODO: remove rubocop ignores and refactor once file not found issue is resolved
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Layout/LineLength
  def convert_to_ptiff
    Rails.logger.info "************ child_object.rb # convert_to_ptiff +++ is the ptiff valid? #{pyramidal_tiff.valid?} *************"
    if pyramidal_tiff.valid?
      if pyramidal_tiff.conversion_information&.[](:width)
        processing_event("PTIFF ready for #{oid}", 'ptiff-ready')
        width_and_height(pyramidal_tiff.conversion_information)
        # Conversion info is true if the ptiff was skipped as already present
      end
      true
    else
      report_ptiff_generation_error
      raise "The child object's image file cannot be found. Please contact the Technical Lead for Digital Collections for assistance. ------------ Message from System: Child Object #{oid} failed to convert PTIFF due to #{pyramidal_tiff.errors.full_messages.join('\n')}"
    end
  end
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity

  def report_ptiff_generation_error
    Rails.logger.info "************ child_object.rb # report_ptiff_generation_error +++ hits method *************"
    Rails.logger.info "************ child_object.rb # report_ptiff_generation_error +++ ptiff errors: #{pyramidal_tiff.errors.full_messages.join("\n")} *************"
    parent_object&.processing_event("The child object's image file cannot be found. Please contact the Technical Lead for Digital Collections for assistance. ------------ Message from System: Child Object #{oid} failed to convert PTIFF due to #{pyramidal_tiff.errors.full_messages.join("\n")}", "failed")
    processing_event("The child object's image file cannot be found. Please contact the Technical Lead for Digital Collections for assistance. ------------ Message from System: Child Object #{oid} failed to convert PTIFF due to #{pyramidal_tiff.errors.full_messages.join("\n")}", "failed")
  end

  def convert_to_ptiff!(force = false)
    Rails.logger.info "************ child_object.rb # convert_to_ptiff!(force = false) +++ is the convert method forced? #{force} *************"
    pyramidal_tiff.force_update = force
    convert_to_ptiff && save!
  end

  def batch_connections_for(batch_process)
    batch_connections.where(batch_process: batch_process)
  end

  private

  def queue_parent_manifest_update
    return unless parent_object.present?
    return unless caption_previously_changed? || label_previously_changed? || order_previously_changed?

    # return if we are already in a BP.
    return if current_batch_process.present?

    GenerateManifestJob.perform_later(parent_object, nil, nil)
  end
end # rubocop:enable  Metrics/ClassLength
