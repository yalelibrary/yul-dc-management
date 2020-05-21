# frozen_string_literal: true

class FixtureIndexingService
  def self.index_fixture_data
    oid_path = Rails.root.join("spec", "fixtures", "fixture_ids.csv")
    mcs = MetadataCloudService.new
    mcs.build_oid_array(oid_path).each do |oid|
      index_to_solr oid
    end
  end

  def self.ladybird_metadata_path
    Rails.root.join('spec','fixtures','ladybird').to_s
  end

  def self.index_to_solr(oid)
    filename = "oid-#{oid}.json"
    file = File.read(File.join(ladybird_metadata_path, filename))
    data_hash = JSON.parse(file)
    solr_doc = {
        id: oid,
        title_tsim: data_hash["title"],
        language_ssim: data_hash["language"],
        description_tesim: data_hash["description"],
        author_tsim: data_hash["creator"],
        oid_ssm: data_hash["oid"]
    }
    solr_core = ENV["SOLR_CORE"] ||= "blacklight-core"
    solr_url = ENV["SOLR_URL"] ||= "http://localhost:8983/solr"
    solr = RSolr.connect url: "#{solr_url}/#{solr_core}"
    solr.add([solr_doc])
    solr.commit
  end
end
