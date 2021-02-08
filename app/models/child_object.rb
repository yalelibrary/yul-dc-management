# frozen_string_literal: true

class ChildObject < ApplicationRecord
  include Statable
  belongs_to :parent_object, foreign_key: 'parent_object_oid', class_name: "ParentObject"
  self.primary_key = 'oid'
  paginates_per 50
  attr_accessor :current_batch_process
  attr_accessor :current_batch_connection

  before_create :check_for_size_and_file

  # Options from iiif presentation api 2.1 - see https://iiif.io/api/presentation/2.1/#viewinghint
  # These are added to the manifest on the canvas level
  def self.viewing_hints
    [nil, "non-paged", "facing-pages"]
  end

  def start_states
    ["ptiff-queued"]
  end

  def finished_states
    ['ptiff-ready-skipped', 'ptiff-ready']
  end

  def check_for_size_and_file
    width_and_height(remote_metadata)
  end

  def processing_event(message, status = 'info', _current_batch_process = parent_object&.current_batch_process, current_batch_connection = parent_object&.current_batch_connection)
    return unless current_batch_connection
    IngestEvent.create!(
      status: status,
      reason: message,
      batch_connection: current_batch_connection
    )
  end

  def remote_ptiff_exists?
    remote_metadata
  end

  def remote_metadata
    S3Service.remote_metadata(remote_ptiff_path)
  end

  def access_master_url
    if ENV['ACCESS_MASTER_MOUNT'] == "s3"
      S3Service.presigned_url(remote_access_master_path, 120)
    else
      "/#{access_master_path}"
    end
  end

  def access_master_path
    return @access_master_path if @access_master_path
    image_mount = ENV['ACCESS_MASTER_MOUNT'] || "data"
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    directory = format("%02d", pairtree_path.first)
    @access_master_path = File.join(image_mount, directory, pairtree_path, "#{oid}.tif")
  end

  def copy_to_access_master_pairtree
    # Don't copy over existing access masters if they already exist
    # TODO: Determine what happens if it's an intentional re-shoot of a child image
    #  1. How is that signalled? (ensure that it's an intentional re-shoot, not accidental duplication)
    #  2. We assume that there is only one access master at a time - BUT we only have one access master pair-tree
    #     across *all* environments (no separation of dev, test, uat, production)
    #     how do we ensure we don't accidentally overwrite something we want to keep?
    if access_master_exists?
      processing_event("Not copied from Goobi package to access master pair-tree, already exists", 'access-master-exists')
      return true
    end
    image_mount = ENV['ACCESS_MASTER_MOUNT'] || "data"
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    directory = format("%02d", pairtree_path.first)
    # Create path to access master if it doesn't exist
    FileUtils.mkdir_p(File.join(image_mount, directory, pairtree_path))
    FileUtils.cp(mets_access_master_path, access_master_path)
    access_master_checksum = Digest::SHA1.file(access_master_path).to_s
    if checksum == access_master_checksum
      processing_event("Copied from Goobi package to access master pair-tree", 'goobi-copied')
      true
    else
      processing_event("Copy from Goobi to access master failed checksum check", 'failed')
      false
    end
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

  def pyramidal_tiff
    @pyramidal_tiff ||= PyramidalTiff.new(self)
  end

  def thumbnail_url
    "#{IiifPresentation.new(parent_object).image_url(oid)}/full/!200,200/0/default.jpg"
  end

  def width_and_height(size)
    return unless size.present? && size[:width].to_i.positive? && size[:height].to_i.positive?
    self.width = size[:width].to_i
    self.height = size[:height].to_i
    self.ptiff_conversion_at = Time.zone.now if remote_ptiff_exists?
    size
  end

  def convert_to_ptiff
    if pyramidal_tiff.valid?
      if pyramidal_tiff.conversion_information&.[](:width)
        processing_event("PTIFF ready for #{oid}", 'ptiff-ready')
        width_and_height(pyramidal_tiff.conversion_information)
        # Conversion info is true if the ptiff was skipped as already present
      end
    else
      parent_object.processing_event("Child Object #{oid} failed to convert PTIFF due to #{pyramidal_tiff.errors.full_messages.join("\n")}", "failed")
    end
  end

  def convert_to_ptiff!(force = false)
    # setting the width to nil will force the PTIFF to be generated.
    self.width = nil if force
    convert_to_ptiff && save!
  end

  def batch_connections_for(batch_process)
    parent_object.batch_connections.where(batch_process: batch_process)
  end
end
