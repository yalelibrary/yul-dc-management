# frozen_string_literal: true

#
# ChildObjects are _deleted_ when parents are destroyed; expect that ChildObjects will be
# deleted _without_ any destroy hooks called.
#

# rubocop:disable ClassLength
class ChildObject < ApplicationRecord
  # rubocop:enable ClassLength
  MAX_ATTEMPTS = 3
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

  # Options from iiif presentation api 2.1 - see https://iiif.io/api/presentation/2.1/#viewinghint
  # These are added to the manifest on the canvas level
  def self.viewing_hints
    [nil, "non-paged", "facing-pages"]
  end

  def start_states
    ["ptiff-queued", "processing-queued"]
  end

  def finished_states
    ['deleted', 'ptiff-ready-skipped', 'ptiff-ready', 'reassociate-complete', 'update-complete']
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

  def access_master_path
    return @access_master_path if @access_master_path
    image_mount = ENV['ACCESS_MASTER_MOUNT'] || "data"
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    directory = format("%02d", pairtree_path.first)
    @access_master_path = File.join(image_mount, directory, pairtree_path, "#{oid}.tif")
  end

  # rubocop:disable  Metrics/MethodLength
  # rubocop:disable  Layout/LineLength
  def copy_to_access_master_pairtree
    # Don't copy over existing access masters if they already exist
    # TODO: Determine what happens if it's an intentional re-shoot of a child image
    #  1. How is that signalled? (ensure that it's an intentional re-shoot, not accidental duplication)
    #  2. We assume that there is only one access master at a time - BUT we only have one access master pair-tree
    #     across *all* environments (no separation of dev, test, uat, production)
    #     how do we ensure we don't accidentally overwrite something we want to keep?
    if access_master_exists? && access_master_checksum_matches?
      processing_event("Not copied from Goobi package to access master pair-tree, already exists", 'access-master-exists')
      return true
    end
    unless mets_access_master_checksum_matches?
      processing_event("Original Copy of checksum does not match", 'failed')
      false
    end
    image_mount = ENV['ACCESS_MASTER_MOUNT'] || "data"
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    directory = format("%02d", pairtree_path.first)
    # Create path to access master if it doesn't exist
    FileUtils.mkdir_p(File.join(image_mount, directory, pairtree_path))
    File.exist?(mets_access_master_path) ? FileUtils.cp(mets_access_master_path, access_master_path) : FileUtils.cp(mets_access_master_path.gsub('.tif', '.TIF').gsub('.jpg', '.JPG'), access_master_path)
    if access_master_checksum_matches?
      processing_event("Copied from Goobi package to access master pair-tree", 'goobi-copied')
      true
    else
      processing_event("Copy from Goobi to access master failed checksum check", 'failed')
      false
    end
  end
  # rubocop:enable  Metrics/MethodLength
  # rubocop:enable  Layout/LineLength

  def access_master_checksum_matches?
    access_master_checksum = Digest::SHA1.file(access_master_path).to_s
    checksum == access_master_checksum
  end

  def mets_access_master_checksum_matches?
    mets_master_checksum = Digest::SHA1.file(mets_access_master_path).to_s
    checksum == mets_master_checksum
  end

  def access_master_exists?
    File.exist?(access_master_path)
  end

  def remote_access_master_path
    return @remote_access_master_path if @remote_access_master_path
    image_bucket = "originals"
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    @remote_access_master_path = File.join(image_bucket, pairtree_path, "#{oid}.tif")
  end

  def remote_ptiff_path
    return @remote_ptiff_path if @remote_ptiff_path
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    @remote_ptiff_path = File.join("ptiffs", pairtree_path, File.basename(access_master_path))
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

  # TODO: remove rubocop ignores and refactor once file not found issue is resolved
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  def convert_to_ptiff
    attempt ||= 1
    Rails.logger.info "************ child_object.rb # convert_to_ptiff +++ is the ptiff valid? #{pyramidal_tiff.valid?} *************"
    if pyramidal_tiff.valid?
      if pyramidal_tiff.conversion_information&.[](:width)
        processing_event("PTIFF ready for #{oid}", 'ptiff-ready')
        width_and_height(pyramidal_tiff.conversion_information)
        # Conversion info is true if the ptiff was skipped as already present
      end
      true
    elsif !pyramidal_tiff.valid? && parent_object&.digital_object_source == 'Preservica'
      if !access_master_exists && (attempt += 1) <= MAX_ATTEMPTS
        Rails.logger.info "************ child_object.rb # convert_to_ptiff +++ File not found at access path: #{access_master_path}.  Retrying copy to access (attempt #{attempt} of #{MAX_ATTEMPTS})"
        PreservicaImageService.new(parent_object.preservica_uri, parent_object.admin_set.key).image_list(parent_object.preservica_representation_type).map do |child_hash|
          parent_object.preservica_copy_to_access(child_hash, oid) unless access_master_exists
        end
      else
        Rails.logger.info "************ child_object.rb # convert_to_ptiff +++ File not downloaded after #{MAX_ATTEMPTS} attempts"
        raise "Child Object #{oid} failed to convert PTIFF due to #{pyramidal_tiff.errors.full_messages.join('\n')}"
      end
    else
      report_ptiff_generation_error
      raise "Child Object #{oid} failed to convert PTIFF due to #{pyramidal_tiff.errors.full_messages.join('\n')}"
    end
  end
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity

  def report_ptiff_generation_error
    Rails.logger.info "************ child_object.rb # report_ptiff_generation_error +++ hits method *************"
    Rails.logger.info "************ child_object.rb # report_ptiff_generation_error +++ ptiff errors: #{pyramidal_tiff.errors.full_messages.join("\n")} *************"
    parent_object&.processing_event("Child Object #{oid} failed to convert PTIFF due to #{pyramidal_tiff.errors.full_messages.join("\n")}", "failed")
    processing_event("Child Object #{oid} failed to convert PTIFF due to #{pyramidal_tiff.errors.full_messages.join("\n")}", "failed")
  end

  def convert_to_ptiff!(force = false)
    Rails.logger.info "************ child_object.rb # convert_to_ptiff!(force = false) +++ is the convert method forced? #{force} *************"
    pyramidal_tiff.force_update = force
    convert_to_ptiff && save!
  end

  def batch_connections_for(batch_process)
    batch_connections.where(batch_process: batch_process)
  end
end # rubocop:enable  Metrics/ClassLength
