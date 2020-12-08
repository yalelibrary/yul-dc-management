# frozen_string_literal: true

namespace :s3download do
  desc "Build urls for downloading child ptiffs from s3"
  task :list_child_ptiffs, [:filename, :bucket] => :environment do |_task, args|
    image_list = CSV.read(args[:filename])
    CSV.open("image_details.csv", "w") do |csv|
      csv << ["OID", "s3 url"]
      image_list.each do |row|
        oid = row[0]
        pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
        destination_key = "ptiffs/#{pairtree_path}/#{oid}.tif"
        # make the urls good for about a day
        row << S3Service.presigned_url(destination_key, 90_000, args[:bucket])
        csv << row
      end
    end
  end
  desc "Copy images from a pairtree in one bucket into another; takes a csv file, source bucket name, target bucket name"
  task :copy_images, [:filename, :source_bucket_name, :target_bucket_name] => :environment do |_task, args|
    image_list = CSV.read(args[:filename])
    s3client = S3Service.instance_variable_get(:@client)
    CSV.open("copy_status.csv", "w") do |csv|
      image_list.each do |row|
        oid = row[0]
        pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
        source_key = "ptiffs/#{pairtree_path}/#{oid}.tif"
        begin
          row << s3client.copy_object(
            bucket: args[:target_bucket_name],
            copy_source: args[:source_bucket_name] + '/' + source_key,
            key: source_key
          ).to_s
        rescue StandardError => e
          puts "Error while copying object #{source_key}: #{e.message}"
          row << e.message
        end
        csv << row
      end
    end
  end
end
