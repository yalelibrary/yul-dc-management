# frozen_string_literal: true

namespace :s3download do
  desc "Build urls for downloading child ptiffs from s3"
    task :list_child_ptiffs, [:filename, :bucket] => :environment do |task, args|
      image_list = CSV.read(args[:filename])
      s3service = S3Service.new
      CSV.open("image_details.csv", "w") do |csv|
        csv << ["OID", "s3 url"]
        image_list.each do |row|
          oid = row[0]
          pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
          destination_key = "ptiffs/#{pairtree_path}/#{oid}.tif"
          #make the urls good for about a day
          row << S3Service.presigned_url(destination_key, 90000, args[:bucket])
          csv << row


  #       next if S3Service.s3_exists?(destination_key)
  #       remote_path = "originals/#{oid}.tif"
  #       next unless S3Service.s3_exists?(remote_path)
  #       object = Aws::S3::Object.new(bucket_name: ENV['S3_SOURCE_BUCKET_NAME'], key: remote_path)
  #       object.copy_to(bucket: ENV['S3_SOURCE_BUCKET_NAME'], key: destination_key)
  #     end
  #   end
      end
    end
  end
end
