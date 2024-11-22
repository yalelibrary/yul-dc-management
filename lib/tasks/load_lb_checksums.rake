# frozen_string_literal: true
namespace :child_objects do
  desc "Read ladybird checksums from TSV"
  task :load_ladybird_checksums, [:files_glob] => :environment do |_, args|
    headers = ['child_oid', 'md5', 'sha256', 'file_name', 'file_size', 'label']
    processed_child_objects_count = 0
    child_objects_not_found = []
    # if connection breaks between files restart from last file
    # if connection breaks between child objects restart from last child object

    # will need
    # way to start from a certain index
    # to store the index prior to failure 

    Dir[args[:files_glob]].each_with_index do |file, index|
      Rails.logger.info("Number of child objects in file: #{File.read(file).each_line.count}")
      open(file) do |f|
        f.each_with_index do |line, index|
          fields = Hash[headers.zip(line.strip.split("\t"))]
          child_object = ChildObject.find_by(oid: fields['child_oid'])
          child_objects_not_found << fields['child_oid'] if child_object.nil?
          next unless child_object
          child_object.md5_checksum = fields['md5']
          child_object.sha256_checksum = fields['sha256']
          child_object.file_size = fields['file_size'].to_i
          child_object.save!
          processed_child_objects_count += 1
        end
      end
    end
    Rails.logger.info("Number of child objects in files processed: #{processed_child_objects_count}")
    Rails.logger.info("Number of child objects not found: #{child_objects_not_found.size}")
    Rails.logger.info("OIDs of child objects not found: #{child_objects_not_found}")
  end
end
