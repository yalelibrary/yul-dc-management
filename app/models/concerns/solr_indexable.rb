# frozen_string_literal: true

module SolrIndexable
  extend ActiveSupport::Concern
  class_methods do
    def solr_index
      solr = SolrService.connection
      # Groups of 500
      find_in_batches do |group|
        solr.add(group.map(&:to_solr).compact)
        solr.commit
      end
    end

    def solr_delete_all
      SolrService.delete_all
    end
  end

  def solr_index
    indexable = to_solr
    return unless indexable.present?
    solr = SolrService.connection
    solr.add([indexable])
    solr.commit
  end

  def solr_delete
    solr = SolrService.connection
    solr.delete_by_id(oid.to_s)
    solr.commit
  end

  def solr_index_job
    SolrIndexJob.perform_later(self)
  end

  def to_solr(json_to_index = nil)
    json_to_index ||= authoritative_json
    return nil if json_to_index.blank? || !manifest_completed?
    {
      # example_suffix: json_to_index[""],
      id: oid.to_s,
      abstract_tesim: json_to_index["abstract"],
      accessionNumber_ssi: json_to_index["accessionNumber"],
      accessRestrictions_tesim: json_to_index["accessRestrictions"],
      alternativeTitle_tesim: json_to_index["alternativeTitle"],
      alternativeTitleDisplay_tesim: json_to_index["alternativeTitleDisplay"],
      archiveSpaceUri_ssi: json_to_index["archiveSpaceUri"],
      creator_ssim: json_to_index["creator"],
      creator_tesim: json_to_index["creator"],
      box_ssim: extract_box_ssim(json_to_index),
      caption_tesim: child_captions,
      child_oids_ssim: child_oids,
      collectionId_ssim: json_to_index["collectionId"],
      collectionId_tesim: json_to_index["collectionId"],
      contents_tesim: json_to_index["contents"],
      contributor_tsim: json_to_index["contributor"],
      contributorDisplay_tsim: json_to_index["contributorDisplay"],
      coordinates_ssim: json_to_index["coordinate"],
      copyrightDate_ssim: json_to_index["copyrightDate"],
      creatorDisplay_tsim: json_to_index["creatorDisplay"],
      date_ssim: json_to_index["date"],
      dateDepicted_ssim: json_to_index["dateDepicted"],
      dateStructured_ssim: json_to_index["dateStructured"], # keeping as ssim for now, dtsi suffix errors out, have invalid values from MC
      dependentUris_ssim: json_to_index["dependentUris"],
      description_tesim: json_to_index["description"],
      digital_ssim: json_to_index["digital"],
      edition_ssim: json_to_index["edition"],
      extent_ssim: json_to_index["extent"],
      extentOfDigitization_ssim: json_to_index["extentOfDigitization"],
      findingAid_ssim: json_to_index["findingAid"],
      folder_ssim: json_to_index["folder"],
      format: json_to_index["format"],
      format_tesim: json_to_index["format"],
      genre_ssim: json_to_index["genre"],
      genre_tesim: json_to_index["genre"],
      geoSubject_ssim: json_to_index["geoSubject"],
      identifierMfhd_ssim: json_to_index["identifierMfhd"],
      identifierShelfMark_ssim: json_to_index["identifierShelfMark"],
      identifierShelfMark_tesim: json_to_index["identifierShelfMark"],
      imageCount_isi: child_object_count,
      indexedBy_tsim: json_to_index["indexedBy"],
      label_tesim: child_labels,
      language_ssim: json_to_index["language"],
      localRecordNumber_ssim: json_to_index["localRecordNumber"],
      material_tesim: json_to_index["material"],
      number_of_pages_ss: json_to_index["numberOfPages"],
      oid_ssi: json_to_index["oid"] || oid,
      orbisBarcode_ssi: json_to_index["orbisBarcode"] || json_to_index["barcode"],
      orbisBibId_ssi: json_to_index["orbisRecord"], # may change to orbisBibId
      partOf_tesim: json_to_index["partOf"],
      partOf_ssim: json_to_index["partOf"],
      projection_tesim: json_to_index["projection"],
      public_bsi: true, # TEMPORARY, makes everything public
      publicationPlace_ssim: json_to_index["publicationPlace"],
      publicationPlace_tesim: json_to_index["publicationPlace"],
      publisher_tesim: json_to_index["publisher"],
      publisher_ssim: json_to_index["publisher"],
      recordType_ssi: json_to_index["recordType"],
      references_tesim: json_to_index["references"],
      repository_ssim: json_to_index["repository"],
      resourceType_ssim: json_to_index["resourceType"],
      resourceType_tesim: json_to_index["resourceType"],
      rights_ssim: json_to_index["rights"],
      rights_tesim: json_to_index["rights"],
      scale_tesim: json_to_index["scale"],
      source_ssim: json_to_index["source"], # refers to source of metadata, e.g. Ladybird, Voyager, etc.
      sourceCreated_tesim: json_to_index["sourceCreated"],
      sourceDate_tesim: json_to_index["sourceDate"],
      sourceEdition_tesim: json_to_index["sourceEdition"], # Not currently in Blacklight application
      sourceNote_tesim: json_to_index["sourceNote"],
      sourceTitle_tesim: json_to_index["sourceTitle"],
      subjectEra_ssim: json_to_index["subjectEra"],
      subjectGeographic_tesim: json_to_index["subjectGeographic"],
      subjectTitle_tsim: json_to_index["subjectTitle"],
      subjectTitleDisplay_tsim: json_to_index["subjectTitleDisplay"],
      subjectName_ssim: json_to_index["subjectName"],
      subjectName_tesim: json_to_index["subjectName"],
      subjectTopic_tesim: json_to_index["subjectTopic"],
      subjectTopic_ssim: json_to_index["subjectTopic"],
      thumbnail_path_ss: representative_thumbnail,
      title_tesim: json_to_index["title"],
      title_ssim: json_to_index["title"],
      uri_ssim: json_to_index["uri"],
      url_suppl_ssim: json_to_index["relatedUrl"],
      visibility_ssi: extract_visibility(json_to_index),
      # fields below this point will be deprecated in a future release
      abstract_ssim: json_to_index["abstract"], # replaced by abstract_tesim
      alternativeTitle_ssim: json_to_index["alternativeTitle"], # replaced by alternativeTitle_tesim
      alternative_title_tsm: json_to_index["alternativeTitleDisplay"], # replaced by alternativeTitleDisplay_tesim
      author_ssim: json_to_index["creator"], # replaced by creator_ssim
      author_tesim: json_to_index["creator"], # replaced by creator_tesim
      author_tsim: json_to_index["creator"], # replaced by author_tesim
      date_tsim: json_to_index["date"], # replaced by date_ssim
      geo_subject_ssim: json_to_index["geoSubject"], # replaced by geoSubject_ssim
      material_ssim: json_to_index["material"], # replaced by material_tesim
      oid_ssim: json_to_index["oid"] || oid, # replaced by oid_ssi
      orbisBarcode_ssim: json_to_index["orbisBarcode"] || json_to_index["barcode"], # replaced by orbisBarcode_ssi
      orbisBibId_ssim: json_to_index["orbisRecord"], # replaced by orbisBibId_ssi
      projection_ssim: json_to_index["projection"], # replaced by projection_tesim
      recordType_ssim: json_to_index["recordType"], # replaced by recordType_ssi
      references_ssim: json_to_index["references"], # replaced by references_tesim
      scale_ssim: json_to_index["scale"], # replaced by scale_tesim
      sourceCreated_ssim: json_to_index["sourceCreated"], # replaced by sourceCreated_tesim
      sourceDate_ssim: json_to_index["sourceDate"], # replaced by sourceDate_tesim
      sourceEdition_ssim: json_to_index["sourceEdition"], # replaced by sourceEdition_tesim
      sourceNote_ssim: json_to_index["sourceNote"], # replaced by sourceNote_tesim
      sourceTitle_ssim: json_to_index["sourceTitle"], # repleaced by sourceTitle_tesim
      subject_topic_tsim: json_to_index["subjectTopic"], # replaced by subjectTopic_tesim and subjectTopic_ssim
      title_tsim: json_to_index["title"] # replaced by title_tesim
    }
  end

  def extract_visibility(json_to_index)
    json_to_index["itemPermission"] || visibility
  end

  # I do not think the current box_ssim is how we want to continue to do deal with differences in field names
  # However I do not think we currently have enough information to create the alternative (Max)
  # Ladybird json_to_index["box"] || Voyager json_to_index["volumeEnumeration"] || ArchiveSpace json_to_index["containerGrouping"]
  def extract_box_ssim(json_to_index)
    json_to_index["box"] || json_to_index["volumeEnumeration"] || json_to_index["containerGrouping"]
  end
end
