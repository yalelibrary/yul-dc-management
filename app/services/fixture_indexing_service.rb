# frozen_string_literal: true

class FixtureIndexingService
  def self.index_fixture_data(metadata_source)
    oid_path = Rails.root.join("spec", "fixtures", "fixture_ids.csv")
    FixtureParsingService.build_oid_array(oid_path).each do |oid|
      next unless FixtureParsingService.fixture_file_to_hash(oid, metadata_source)
      index_from_fixture_to_solr(oid, metadata_source)
    end
  end

  def self.index_from_fixture_to_solr(oid, metadata_source)
    id_prefix = FixtureParsingService.file_prefix(metadata_source)
    return nil unless FixtureParsingService.fixture_file_to_hash(oid, metadata_source)
    data_hash = FixtureParsingService.fixture_file_to_hash(oid, metadata_source)
    solr_doc = build_solr_document(id_prefix, oid, data_hash)
    solr = SolrService.connection
    solr.add([solr_doc])
    solr.commit
  end

  def self.index_from_database_to_solr
    solr = SolrService.connection
    ParentObject.all.map do |parent_object|
      data_hash = parent_object.authoritative_json
      id_prefix = parent_object.authoritative_metadata_source.file_prefix
      oid = parent_object.oid
      solr_doc = build_solr_document(id_prefix, oid, data_hash)
      solr.add([solr_doc])
    end
    solr.commit
  end

  def self.metadata_path(metadata_source)
    Rails.root.join('spec', 'fixtures', metadata_source).to_s
  end

  def self.build_solr_document(id_prefix, oid, data_hash)
    {
      # example_suffix: data_hash[""],
      id: "#{id_prefix}#{oid}",
      abstract_tesim: data_hash["abstract"],
      accessionNumber_ssi: data_hash["accessionNumber"],
      accessRestrictions_tesim: data_hash["accessRestrictions"],
      alternativeTitle_tesim: data_hash["alternativeTitle"],
      alternativeTitleDisplay_tesim: data_hash["alternativeTitleDisplay"],
      archiveSpaceUri_ssi: data_hash["archiveSpaceUri"],
      author_ssim: data_hash["creator"],
      author_tsim: data_hash["creator"],
      box_ssim: extract_box_ssim(data_hash),
      caption_tesim: data_hash["caption"],
      collectionId_ssim: data_hash["collectionId"],
      collectionId_tesim: data_hash["collectionId"],
      contents_tesim: data_hash["contents"],
      contributor_tsim: data_hash["contributor"],
      contributorDisplay_tsim: data_hash["contributorDisplay"],
      coordinates_ssim: data_hash["coordinate"],
      copyrightDate_ssim: data_hash["copyrightDate"],
      creatorDisplay_tsim: data_hash["creatorDisplay"],
      date_ssim: data_hash["date"],
      dateDepicted_ssim: data_hash["dateDepicted"],
      dateStructured_ssim: data_hash["dateStructured"], # keeping as ssim for now, dtsi suffix errors out, have invalid values from MC
      dependentUris_ssim: data_hash["dependentUris"],
      description_tesim: data_hash["description"],
      digital_ssim: data_hash["digital"],
      edition_ssim: data_hash["edition"],
      extent_ssim: data_hash["extent"],
      extentOfDigitization_ssim: data_hash["extentOfDigitization"],
      findingAid_ssim: data_hash["findingAid"],
      folder_ssim: data_hash["folder"],
      format: data_hash["format"],
      genre_ssim: data_hash["genre"],
      geoSubject_ssim: data_hash["geoSubject"],
      identifierMfhd_ssim: data_hash["identifierMfhd"],
      identifierShelfMark_ssim: data_hash["identifierShelfMark"],
      illustrativeMatter_tesim: data_hash["illustrativeMatter"],
      indexedBy_tsim: data_hash["indexedBy"],
      language_ssim: data_hash["language"],
      localRecordNumber_ssim: data_hash["localRecordNumber"],
      material_tesim: data_hash["material"],
      number_of_pages_ss: data_hash["numberOfPages"],
      oid_ssi: data_hash["oid"] || oid,
      orbisBarcode_ssi: data_hash["orbisBarcode"] || data_hash["barcode"],
      orbisBibId_ssi: data_hash["orbisRecord"], # may change to orbisBibId
      partOf_tesim: data_hash["partOf"],
      partOf_ssim: data_hash["partOf"],
      projection_tesim: data_hash["projection"],
      public_bsi: true, # TEMPORARY, makes everything public
      publicationPlace_ssim: data_hash["publicationPlace"],
      publicationPlace_tesim: data_hash["publicationPlace"],
      publisher_tesim: data_hash["publisher"],
      publisher_ssim: data_hash["publisher"],
      recordType_ssi: data_hash["recordType"],
      references_tesim: data_hash["references"],
      repository_ssim: data_hash["repository"],
      resourceType_ssim: data_hash["resourceType"],
      rights_ssim: data_hash["rights"],
      rights_tesim: data_hash["rights"],
      scale_tesim: data_hash["scale"],
      source_ssim: data_hash["source"], # refers to source of metadata, e.g. Ladybird, Voyager, etc.
      sourceCreated_tesim: data_hash["sourceCreated"],
      sourceDate_tesim: data_hash["sourceDate"],
      sourceEdition_tesim: data_hash["sourceEdition"], # Not currently in Blacklight application
      sourceNote_tesim: data_hash["sourceNote"],
      sourceTitle_tesim: data_hash["sourceTitle"],
      subjectEra_ssim: data_hash["subjectEra"],
      subjectGeographic_tesim: data_hash["subjectGeographic"],
      subjectTitle_tsim: data_hash["subjectTitle"],
      subjectTitleDisplay_tsim: data_hash["subjectTitleDisplay"],
      subjectName_ssim: data_hash["subjectName"],
      subjectName_tesim: data_hash["subjectName"],
      subjectTopic_tesim: data_hash["subjectTopic"],
      subjectTopic_ssim: data_hash["subjectTopic"],
      title_tesim: data_hash["title"],
      uri_ssim: data_hash["uri"],
      url_suppl_ssim: data_hash["relatedUrl"],
      visibility_ssi: extract_visibility(oid, data_hash),
      # fields below this point will be deprecated in a future release
      abstract_ssim: data_hash["abstract"], # replaced by abstract_tesim
      alternativeTitle_ssim: data_hash["alternativeTitle"], # replaced by alternativeTitle_tesim
      alternative_title_tsm: data_hash["alternativeTitleDisplay"], # replaced by alternativeTitleDisplay_tesim
      date_tsim: data_hash["date"], # replaced by date_ssim
      geo_subject_ssim: data_hash["geoSubject"], # replaced by geoSubject_ssim
      illustrative_matter_tsi: data_hash["illustrativeMatter"], # replaced by illustrativeMatter_tesim
      material_ssim: data_hash["material"], # replaced by material_tesim
      oid_ssim: data_hash["oid"] || oid, # replaced by oid_ssi
      orbisBarcode_ssim: data_hash["orbisBarcode"] || data_hash["barcode"], # replaced by orbisBarcode_ssi
      orbisBibId_ssim: data_hash["orbisRecord"], # replaced by orbisBibId_ssi
      projection_ssim: data_hash["projection"], # replaced by projection_tesim
      recordType_ssim: data_hash["recordType"], # replaced by recordType_ssi
      references_ssim: data_hash["references"], # replaced by references_tesim
      scale_ssim: data_hash["scale"], # replaced by scale_tesim
      sourceCreated_ssim: data_hash["sourceCreated"], # replaced by sourceCreated_tesim
      sourceDate_ssim: data_hash["sourceDate"], # replaced by sourceDate_tesim
      sourceEdition_ssim: data_hash["sourceEdition"], # replaced by sourceEdition_tesim
      sourceNote_ssim: data_hash["sourceNote"], # replaced by sourceNote_tesim
      sourceTitle_ssim: data_hash["sourceTitle"], # repleaced by sourceTitle_tesim
      subject_topic_tsim: data_hash["subjectTopic"], # replaced by subjectTopic_tesim and subjectTopic_ssim
      title_tsim: data_hash["title"] # replaced by title_tesim
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
