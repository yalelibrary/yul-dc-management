# frozen_string_literal: true

class FixtureIndexingService
  def self.index_fixture_data(metadata_source)
    oid_path = Rails.root.join("spec", "fixtures", "fixture_ids.csv")
    FixtureParsingService.build_oid_array(oid_path).each do |oid|
      next unless FixtureParsingService.fixture_file_to_hash(oid, metadata_source)
      index_to_solr(oid, metadata_source)
    end
  end

  def self.index_to_solr(oid, metadata_source)
    id_prefix = FixtureParsingService.file_prefix(metadata_source)
    return nil unless FixtureParsingService.fixture_file_to_hash(oid, metadata_source)
    data_hash = FixtureParsingService.fixture_file_to_hash(oid, metadata_source)
    solr_doc = build_solr_document(id_prefix, oid, data_hash)
    solr = SolrService.connection
    solr.add([solr_doc])
    solr.commit
  end

  def self.metadata_path(metadata_source)
    Rails.root.join('spec', 'fixtures', metadata_source).to_s
  end

  def self.build_solr_document(id_prefix, oid, data_hash)
    {
      id: "#{id_prefix}#{oid}",
      abstract_ssim: data_hash["abstract"],
      alternativeTitle_ssim: data_hash["alternativeTitle"],
      alternative_title_tsm: data_hash["alternativeTitleDisplay"],
      author_ssim: data_hash["creator"],
      author_tsim: data_hash["creator"],
      box_ssim: extract_box_ssim(data_hash),
      coordinates_ssim: data_hash["coordinate"],
      copyrightDate_ssim: data_hash["copyrightDate"],
      date_tsim: data_hash["date"], # Not clear what date this refers to, not in Blacklight
      dateStructured_ssim: data_hash["dateStructured"],
      description_tesim: data_hash["description"],
      digital_ssim: data_hash["digital"],
      edition_ssim: data_hash["edition"],
      extent_ssim: data_hash["extent"],
      extentOfDigitization_ssim: data_hash["extentOfDigitization"],
      findingAid_ssim: data_hash["findingAid"],
      folder_ssim: data_hash["folder"],
      format: data_hash["format"],
      genre_ssim: data_hash["genre"],
      geo_subject_ssim: data_hash["geoSubject"],
      identifierMfhd_ssim: data_hash["identifierMfhd"],
      identifierShelfMark_ssim: data_hash["identifierShelfMark"],
      illustrative_matter_tsi: data_hash["illustrativeMatter"],
      language_ssim: data_hash["language"],
      material_ssim: data_hash["material"],
      number_of_pages_ss: data_hash["numberOfPages"],
      oid_ssim: data_hash["oid"] || oid,
      orbisBarcode_ssim: data_hash["orbisBarcode"] || data_hash["barcode"],
      orbisBibId_ssim: data_hash["orbisRecord"], # may change to orbisBibId
      partOf_ssim: data_hash["partOf"],
      projection_ssim: data_hash["projection"],
      public_bsi: true, # TEMPORARY, makes everything public
      publicationPlace_ssim: data_hash["publicationPlace"],
      publisher_ssim: data_hash["publisher"],
      recordType_ssim: data_hash["recordType"],
      references_ssim: data_hash["references"],
      resourceType_ssim: data_hash["resourceType"],
      rights_ssim: data_hash["rights"],
      scale_ssim: data_hash["scale"],
      source_ssim: data_hash["source"], # refers to source of metadata, e.g. Ladybird, Voyager, etc.
      sourceCreated_ssim: data_hash["sourceCreated"],
      sourceDate_ssim: data_hash["sourceDate"],
      sourceEdition_ssim: data_hash["sourceEdition"], # Not currently in Blacklight application
      sourceNote_ssim: data_hash["sourceNote"],
      sourceTitle_ssim: data_hash["sourceTitle"],
      subject_topic_tsim: data_hash["subjectTopic"],
      subjectName_ssim: data_hash["subjectName"],
      title_tsim: data_hash["title"],
      uri_ssim: data_hash["uri"],
      url_suppl_ssim: data_hash["relatedUrl"],
      visibility_ssi: extract_visibility(oid, data_hash),
    }
  end

  def self.extract_visibility(oid, data_hash)
    data_hash["itemPermission"] || ParentObject.find_by(oid: oid)&.visibility
  end

  # I do not think the current box_ssim is how we want to continue to do deal with differences in field names
  # However I do not think we currently have enough information to create the alternative (Max)
  # Ladybird data_hash["box"] || Voyager data_hash["volumeEnumeration"] || ArchiveSpace data_hash["containerGrouping"]
  def self.extract_box_ssim(data_hash)
    data_hash["box"] || data_hash["volumeEnumeration"] || data_hash["containerGrouping"]
  end
end
