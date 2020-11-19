# frozen_string_literal: true

class ChildObject < ApplicationRecord
  include Statable
  belongs_to :parent_object, foreign_key: 'parent_object_oid', class_name: "ParentObject"
  self.primary_key = 'oid'
  paginates_per 50
  attr_accessor :current_batch_process
  attr_accessor :current_batch_connection

  before_create :check_for_size_and_file

  def start_states
    ["ptiff-queued"]
  end

  def finished_states
    ['ptiff-ready', 'ptiff-ready-skipped']
  end

  def check_for_size_and_file
    width_and_height(remote_metadata)
  end

  def processing_event(message, status = 'info', current_batch_process = parent_object&.current_batch_process, _current_batch_connection = parent_object&.current_batch_connection)
    IngestNotification.with(parent_object_id: parent_object&.id, child_object_id: id, status: status, reason: message, batch_process_id: current_batch_process&.id).deliver(User.first)
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
    "#{IiifPresentation.new(parent_object).image_url(oid)}/full/200,/0/default.jpg"
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
      width_and_height(pyramidal_tiff.conversion_information)
      if pyramidal_tiff.conversion_information&.[](:width)
        processing_event("PTIFF ready for #{oid}", 'ptiff-ready')
        width_and_height(pyramidal_tiff.conversion_information)
      end
      # Conversion info is blank if the ptiff was skipped as already present
    else
      parent_object.processing_event("Child Object #{oid} failed to convert PTIFF due to #{pyramidal_tiff.errors.full_messages.join("\n")}", "failed")
    end
  end

  def convert_to_ptiff!
    convert_to_ptiff && save!
  end
end
