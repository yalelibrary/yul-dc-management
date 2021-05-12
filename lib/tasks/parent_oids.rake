# frozen_string_literal: true

namespace :parent_oids do
  desc "Create list of random selection of parent oids"
  task random: :environment, [:samples] { |_t, args|
    oid_path = Rails.root.join("spec", "fixtures", "public_oids_comma.csv")
    fixture_ids_table = CSV.read(oid_path, headers: true)
    oids = fixture_ids_table.by_col[0]
    random_parent_oids = oids.sample(args[:samples].to_i)
    CSV.open(File.join("data", "random_parent_oids.csv"), "wb") do |csv|
      csv << ["oid"]
      random_parent_oids.each { |oid| csv << [oid] }
    end
  }

  desc "Update Ladybird fixtures"
  task update_ladybird_fixtures: :environment do
    metadata_source = MetadataSource.find_by(metadata_cloud_name: "ladybird")
    oids.each do |oid|
      mc_url = "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/ladybird/oid/#{oid}?include-children=1"
      full_response = metadata_source.mc_get(mc_url)
      case full_response.status
      when 200
        response_text = full_response.body.to_str
        S3Service.upload("ladybird/#{oid}.json", response_text)
        response_text = JSON.parse(response_text)
        File.write("spec/fixtures/ladybird/#{oid}.json", JSON.pretty_generate(response_text))
        puts "Ladybird fixture for #{oid} saved"
      else
        puts "Ladybird record not retrieved for #{oid}"
      end
    end
  end

  desc "Update Voyager fixtures"
  task update_voyager_fixtures: :environment do
    metadata_source = MetadataSource.find_by(metadata_cloud_name: "ils")
    oids.each do |oid|
      ladybird_json = JSON.parse(File.open("spec/fixtures/ladybird/#{oid}.json").read)
      mc_url = voyager_cloud_url(ladybird_json)
      full_response = metadata_source.mc_get(mc_url)
      case full_response.status
      when 200
        response_text = full_response.body.to_str
        S3Service.upload("ils/V-#{oid}.json", response_text)
        response_text = JSON.parse(response_text)
        File.write("spec/fixtures/ils/V-#{oid}.json", JSON.pretty_generate(response_text))
        puts "Voyager fixture for #{oid} saved"
      else
        puts "Voyager record not retrieved for #{oid}"
      end
    end
  end

  desc "Update ArchiveSpace fixtures"
  task update_aspace_fixtures: :environment do
    metadata_source = MetadataSource.find_by(metadata_cloud_name: "aspace")
    oids.each do |oid|
      ladybird_json = JSON.parse(File.open("spec/fixtures/ladybird/#{oid}.json").read)
      mc_url = "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/aspace#{ladybird_json['archiveSpaceUri']}"
      full_response = metadata_source.mc_get(mc_url)
      case full_response.status
      when 200
        response_text = full_response.body.to_str
        S3Service.upload("aspace/AS-#{oid}.json", response_text)
        response_text = JSON.parse(response_text)
        File.write("spec/fixtures/aspace/AS-#{oid}.json", JSON.pretty_generate(response_text))
        puts "ArchiveSpace fixture for #{oid} saved"
      else
        puts "ArchiveSpace record not retrieved for #{oid}"
      end
    end
  end

  def voyager_cloud_url(ladybird_json)
    orbis_bib = ladybird_json['orbisRecord'] || ladybird_json['orbisBibId']
    identifier_block = if ladybird_json["orbisBarcode"].nil?
                         "/bib/#{orbis_bib}"
                       else
                         "/barcode/#{ladybird_json['orbisBarcode']}?bib=#{orbis_bib}"
                       end
    "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}/ils#{identifier_block}"
  end

  def oids
    oid_path = Rails.root.join("db", "parent_oids.csv")
    fixture_ids_table = CSV.read(oid_path, headers: true)
    fixture_ids_table.by_col[0]
  end
end
