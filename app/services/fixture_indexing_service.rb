# frozen_string_literal: true

class FixtureIndexingService
  def self.index_fixture_data(metadata_source)
    oid_path = Rails.root.join("spec", "fixtures", "fixture_ids.csv")
    mcs = MetadataCloudService.new
    mcs.build_oid_array(oid_path).each do |oid|
      next unless mcs.fixture_file_to_hash(oid, metadata_source)
      index_to_solr(oid, metadata_source)
    end
  end

  def self.metadata_path(metadata_source)
    Rails.root.join('spec', 'fixtures', metadata_source).to_s
  end

  def build_solr_document(id_prefix, oid, data_hash)
    {
      id: "#{id_prefix}#{oid}",
      title_tsim: data_hash["title"],
      # title_vern_ssim # title in the vernacular
      # subtitle_tsim
      # subtitle_vern_ssim # subtitle in the vernacular
      author_ssim: data_hash["creator"],
      author_tsim: data_hash["creator"],
      # author_vern_ssim # author in the vernacular
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
      oid_ssim: data_hash["oid"] || oid,
      identifierMfhd_ssim: data_hash["identifierMfhd"],
      identifierShelfMark_ssim: data_hash["identifierShelfMark"],
      box_ssim: extract_box_ssim(data_hash),
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
      visibility_ssi: extract_visibility(oid, data_hash)
    }
  end

  def extract_visibility(oid, data_hash)
    data_hash["itemPermission"] || ParentObject.find_by(oid: oid)&.visibility
  end

  # I do not think the current box_ssim is how we want to continue to do deal with differences in field names
  # However I do not think we currently have enough information to create the alternative (Max)
  # Ladybird data_hash["box"] || Voyager data_hash["volumeEnumeration"] || ArchiveSpace data_hash["containerGrouping"]
  def extract_box_ssim(data_hash)
    data_hash["box"] || data_hash["volumeEnumeration"] || data_hash["containerGrouping"]
  end

  def self.index_to_solr(oid, metadata_source)
    mcs = MetadataCloudService.new
    fis = FixtureIndexingService.new
    id_prefix = mcs.file_prefix(metadata_source)
    return nil unless mcs.fixture_file_to_hash(oid, metadata_source)
    data_hash = mcs.fixture_file_to_hash(oid, metadata_source)
    solr_doc = fis.build_solr_document(id_prefix, oid, data_hash)
    solr = SolrService.connection
    solr.add([solr_doc])
    solr.commit
  end
end
