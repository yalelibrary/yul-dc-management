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
      language_ssim: data_hash["language"],
      description_tesim: data_hash["description"],
      author_tsim: data_hash["creator"],
      oid_ss: data_hash["oid"],
      format_ssim: data_hash["format"],
      orbis_bib_id_ssim: data_hash["orbisRecord"], # may change to orbisBibId
      alternative_title_tim: data_hash["alternativeTitle"],
      alternative_title_tsm: data_hash["alternativeTitleDisplay"],
      source_ssi: data_hash["source"],
      record_type_ssi: data_hash["recordType"],
      identifier_mfhd_ssi: data_hash["identifierMfhd"],
      identifier_shelf_mark_tsi: data_hash["identifierShelfMark"],
      box_tsi: data_hash["identifierShelfMark"],
      source_title_tsi: data_hash["sourceTitle"],
      source_date_tsi: data_hash["sourceDate"],
      source_edition_tsi: data_hash["sourceEdition"],
      source_note_tsi: data_hash["sourceNote"],
      extent_of_digitization_tsim: data_hash["extentOfDigitization"],
      date_tsim: data_hash["date"],
      extent_tsim: data_hash["extent"],
      subject_name_tsim: data_hash["subjectName"],
      subject_topic_tsim: data_hash["subjectTopic"],
      genre_tsim: data_hash["genre"],
      part_of_tsi: data_hash["partOf"],
      rights_tsim: data_hash["rights"],
      barcode_tsi: data_hash["orbisBarcode"] || data_hash["barcode"],
      finding_aid_tsim: data_hash["findingAid"],
      references_tsim: data_hash["references"],
      date_structured_ssim: data_hash["dateStructured"],
      publication_place_tsim: data_hash["publicationPlace"],
      folder_tsi: data_hash["folder"],
      number_of_pages_ss: data_hash["numberOfPages"],
      resource_type_tsi: data_hash["resourceType"],
      source_created_tsi: data_hash["sourceCreated"],
      edition_tsim: data_hash["edition"],
      uri_ssi: data_hash["uri"],
      abstract_tsim: data_hash["abstract"],
      geo_subject_tsi: data_hash["geoSubject"],
      illustrative_matter_tsi: data_hash["illustrativeMatter"],
      publisher_tsim: data_hash["publisher"],
      material_tsim: data_hash["material"],
      scale_tsi: data_hash["scale"],
      digital_tsi: data_hash["digital"],
      coordinate_tsim: data_hash["coordinate"],
      copyright_date_ssim: data_hash["copyrightDate"],
      projection_tsim: data_hash["projection"],
      public_bsi: true
    }
    solr_core = ENV["SOLR_CORE"] ||= "blacklight-core"
    solr_url = ENV["SOLR_URL"] ||= "http://localhost:8983/solr"
    solr = RSolr.connect url: "#{solr_url}/#{solr_core}"
    solr.add([solr_doc])
    solr.commit
  end
end
