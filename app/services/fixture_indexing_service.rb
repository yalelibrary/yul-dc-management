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
    Rails.root.join('spec', 'fixtures', 'ladybird').to_s
  end

  def self.index_to_solr(oid)
    filename = "oid-#{oid}.json"
    file = File.read(File.join(ladybird_metadata_path, filename))
    data_hash = JSON.parse(file)
    solr_doc = {
      id: oid,
      title_tsim: data_hash["title"],
      title_vern_ssim: data_hash["title"],
      # subtitle_tsim
      # subtitle_vern_ssim
      author_tsim: data_hash["creator"],
      author_vern_ssim: data_hash["creator"],
      extent_ssim: data_hash["extent"],
      format: data_hash["format"],
      # url_fulltext_ssim
      url_suppl_ssim: data_hash["relatedUrl"],
      language_ssim: data_hash["language"],
      # published_ssim
      # published_vern_ssim
      # lc_callnum_ssim
      # isbn_ssim
      description_tesim: data_hash["description"],
      abstract_ssim: data_hash["abstract"],
      alternativeTitle_ssim: data_hash["alternativeTitle"],
      alternative_title_tsm: data_hash["alternativeTitleDisplay"],
      genre_ssim: data_hash["genre"],
      geo_subject_ssim: data_hash["geoSubject"],
      resourceType_ssim: data_hash["resourceType"],
      subjectName_ssim: data_hash["subjectName"],
      subject_topic_tsim: data_hash["subjectTopic"],
      extentOfDigitization_ssim: data_hash["extentOfDigitization"],
      rights_ssim: data_hash["rights"],
      publicationPlace_ssim: data_hash["publicationPlace"],
      sourceCreated_ssim: data_hash["sourceCreated"],
      publisher_ssim: data_hash["publisher"],
      copyrightDate_ssim: data_hash["copyrightDate"],
      source_ssim: data_hash["source"], # refers to source of metadata, e.g. Ladybird, Voyager, etc.
      recordType_ssim: data_hash["recordType"],
      sourceTitle_ssim: data_hash["sourceTitle"],
      sourceDate_ssim: data_hash["sourceDate"],
      sourceNote_ssim: data_hash["sourceNote"],
      sourceEdition_ssim: data_hash["sourceEdition"], # Not currently in Blacklight application
      references_ssim: data_hash["references"],
      dateStructured_ssim: data_hash["dateStructured"],
      # children_ssim
      # importUrl_ssim
      illustrative_matter_tsi: data_hash["illustrativeMatter"],
      oid_ssim: data_hash["oid"],
      identifierMfhd_ssim: data_hash["identifierMfhd"],
      identifierShelfMark_ssim: data_hash["identifierShelfMark"],
      box_ssim: data_hash["identifierShelfMark"],
      folder_ssim: data_hash["folder"],
      orbisBibId_ssim: data_hash["orbisRecord"], # may change to orbisBibId
      orbisBarcode_ssim: data_hash["orbisBarcode"] || data_hash["barcode"],
      findingAid_ssim: data_hash["findingAid"],
      # collectionId_ssim
      edition_ssim: data_hash["edition"],
      uri_ssim: data_hash["uri"],
      partOf_ssim: data_hash["partOf"],
      number_of_pages_ss: data_hash["numberOfPages"],
      material_ssim: data_hash["material"],
      scale_ssim: data_hash["scale"],
      digital_ssim: data_hash["digital"],
      coordinates_ssim: data_hash["coordinate"],
      projection_ssim: data_hash["projection"],

      date_tsim: data_hash["date"], # Not clear what date this refers to, not in Blacklight
      public_bsi: true, # TEMPORARY, makes everything public
      visibility_ssi: data_hash["itemPermission"]
    }
    solr_core = ENV["SOLR_CORE"] ||= "blacklight-core"
    solr_url = ENV["SOLR_URL"] ||= "http://localhost:8983/solr"
    solr = RSolr.connect url: "#{solr_url}/#{solr_core}"
    solr.add([solr_doc])
    solr.commit
  end
end
