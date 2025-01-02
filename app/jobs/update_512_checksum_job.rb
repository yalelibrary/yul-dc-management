# frozen_string_literal: true

class Update512ChecksumJob < ApplicationJob
  def perform(child_object)
    child_object.sha512_checksum = child_object&.access_sha512_checksum
    child_object.file_size = child_object&.access_file_size
    child_object.checksum = nil
    child_object.md5_checksum = nil
    child_object.sha256_checksum = nil
  end
end