# frozen_string_literal: true

namespace :access_masters do
  desc "Copy fixtures to S3"
  task copy_access_masters: :environment do
    ParentObject.all.each do |parent_object|
      parent_object.child_objects.each do |child|
        oid = child.oid
        remote_path = "originals/#{oid}.tif"
        next unless S3Service.s3_exists?(remote_path)
        object = Aws::S3::Object.new(bucket_name: ENV['S3_SOURCE_BUCKET_NAME'], key: remote_path)
        pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
        object.copy_to(bucket: ENV['S3_SOURCE_BUCKET_NAME'], key: "originals/#{pairtree_path}/#{oid}.tif")
      end
    end
  end
end
