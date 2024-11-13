# frozen_string_literal: true
namespace :child_objects do
  desc "Read ladybird checksums from TSV"
  task :load_ladybird_checksums, [:files_glob] => :environment do |_, args|
    headers = ['child_oid', 'md5', 'sha256', 'file_name', 'file_size', 'label']
    Dir[args[:files_glob]].each do |file|
      open(file) do |f|
        f.each do |line|
          fields = Hash[headers.zip(line.strip.split("\t"))]
          child_object = ChildObject.find_by(oid: fields['child_oid'])
          next unless child_object
          child_object.md5_checksum = fields['md5']
          child_object.sha256_checksum = fields['sha256']
          child_object.file_size = fields['file_size'].to_i
          child_object.save!
        end
      end
    end
  end
end
