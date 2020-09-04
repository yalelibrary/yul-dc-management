namespace :manifests do
  desc "Copy fixtures to S3"
  task copy_fixtures_to_s3: :environment do
    Dir.glob(Rails.root.join("data", "yul-dc-fixture-manifests", "*.json")).each do |file|
      oid = File.basename(file).gsub(".json", "")
      pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
      S3Service.upload("manifests/#{pairtree_path}/#{oid}.json", File.read(file))
    end
  end
end
