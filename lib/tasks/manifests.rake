# frozen_string_literal: true

namespace :manifests do
  desc "Copy fixtures to S3"
  task copy_fixtures_to_s3: :environment do
    Dir.glob(Rails.root.join("data", "yul-dc-fixture-manifests", "*.json")).each do |file|
      oid = File.basename(file).gsub(".json", "")
      pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
      S3Service.upload("manifests/#{pairtree_path}/#{oid}.json", File.read(file))
    end
  end

  desc "Remove .json from manifest ids in fixture files"
  task remove_dot_json: :environment do
    Dir.glob(Rails.root.join("data", "yul-dc-fixture-manifests", "*.json")).each do |file|
      tfile = Tempfile.new(File.basename(file))
      File.open(file, 'r') do |json_file|
        json = JSON.parse(json_file.read)
        json["@id"] = json["@id"].gsub(".json", "")
        tfile.write(JSON.pretty_generate(json))
      end
      tfile.close
      FileUtils.mv(tfile.path, file)
    end
  end
end
