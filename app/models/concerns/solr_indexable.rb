# frozen_string_literal: true

module SolrIndexable
  extend ActiveSupport::Concern
  class_methods do
    def solr_index
      SolrReindexAllJob.perform_later
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
      archiveSpaceUri_ssi: aspace_uri,
      callNumber_ssim: json_to_index["callNumber"],
      callNumber_tesim: json_to_index["callNumber"],
      caption_tesim: child_captions,
      child_oids_ssim: child_oids,
      collectionId_ssim: json_to_index["collectionId"],
      collectionId_tesim: json_to_index["collectionId"],
      containerGrouping_ssim: extract_container_information(json_to_index),
      contents_tesim: json_to_index["contents"],
      contributor_tsim: json_to_index["contributor"],
      contributorDisplay_tsim: json_to_index["contributorDisplay"],
      coordinates_ssim: json_to_index["coordinate"],
      copyrightDate_ssim: json_to_index["copyrightDate"],
      creator_ssim: json_to_index["creator"],
      creator_tesim: json_to_index["creator"],
      creatorDisplay_tsim: json_to_index["creatorDisplay"],
      creationPlace_ssim: json_to_index["creationPlace"],
      creationPlace_tesim: json_to_index["creationPlace"],
      date_ssim: json_to_index["date"],
      dateDepicted_ssim: json_to_index["dateDepicted"],
      year_isim: expand_date_structured(json_to_index["dateStructured"]),
      dateStructured_ssim: json_to_index["dateStructured"],
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
      imageCount_isi: child_object_count,
      indexedBy_tsim: json_to_index["indexedBy"],
      label_tesim: child_labels,
      language_ssim: json_to_index["language"],
      localRecordNumber_ssim: json_to_index["localRecordNumber"],
      material_tesim: json_to_index["material"],
      number_of_pages_ss: json_to_index["numberOfPages"],
      oid_ssi: oid,
      orbisBarcode_ssi: barcode,
      orbisBibId_ssi: bib, # may change to orbisBibId
      preferredCitation_tesim: json_to_index["preferredCitation"],
      projection_tesim: json_to_index["projection"],
      public_bsi: true, # TEMPORARY, makes everything public
      publisher_tesim: json_to_index["publisher"],
      publisher_ssim: json_to_index["publisher"],
      recordType_ssi: json_to_index["recordType"],
      repository_ssim: json_to_index["repository"],
      resourceType_ssim: json_to_index["itemType"],
      resourceType_tesim: json_to_index["itemType"],
      rights_ssim: rights_statement,
      rights_tesim: rights_statement,
      scale_tesim: json_to_index["scale"],
      source_ssim: json_to_index["source"], # refers to source of metadata, e.g. Ladybird, Voyager, etc.
      sourceCreated_tesim: json_to_index["sourceCreated"],
      sourceDate_tesim: json_to_index["sourceDate"],
      sourceEdition_tesim: json_to_index["sourceEdition"], # Not currently in Blacklight application
      sourceNote_tesim: json_to_index["sourceNote"],
      sourceTitle_tesim: json_to_index["sourceTitle"],
      subjectEra_ssim: json_to_index["subjectEra"],
      subjectGeographic_ssim: json_to_index["subjectGeographic"],
      subjectGeographic_tesim: json_to_index["subjectGeographic"],
      subjectTitle_tsim: json_to_index["subjectTitle"],
      subjectTitleDisplay_tsim: json_to_index["subjectTitleDisplay"],
      subjectName_ssim: json_to_index["subjectName"],
      subjectName_tesim: json_to_index["subjectName"],
      subjectTopic_tesim: json_to_index["subjectTopic"],
      subjectTopic_ssim: json_to_index["subjectTopic"],
      thumbnail_path_ss: representative_thumbnail_url,
      title_tesim: json_to_index["title"],
      title_ssim: json_to_index["title"],
      uri_ssim: json_to_index["uri"],
      url_suppl_ssim: json_to_index["relatedUrl"],
      visibility_ssi: visibility,
      # fields below this point will be deprecated in a future release
      abstract_ssim: json_to_index["abstract"], # replaced by abstract_tesim
      alternativeTitle_ssim: json_to_index["alternativeTitle"], # replaced by alternativeTitle_tesim
      alternative_title_tsm: json_to_index["alternativeTitleDisplay"], # replaced by alternativeTitleDisplay_tesim
      author_ssim: json_to_index["creator"], # replaced by creator_ssim
      author_tesim: json_to_index["creator"], # replaced by creator_tesim
      author_tsim: json_to_index["creator"], # replaced by author_tesim
      box_ssim: extract_container_information(json_to_index), # replaced by containerGrouping
      date_tsim: json_to_index["date"], # replaced by date_ssim
      identifierShelfMark_ssim: json_to_index["callNumber"], # replaced by callNumber
      identifierShelfMark_tesim: json_to_index["callNumber"], # replaced by callNumber
      geo_subject_ssim: json_to_index["geoSubject"], # replaced by geoSubject_ssim
      material_ssim: json_to_index["material"], # replaced by material_tesim
      oid_ssim: oid, # replaced by oid_ssi
      orbisBarcode_ssim: json_to_index["orbisBarcode"] || json_to_index["barcode"], # replaced by orbisBarcode_ssi
      orbisBibId_ssim: json_to_index["orbisBibId"], # replaced by orbisBibId_ssi
      partOf_tesim: json_to_index["partOf"],
      partOf_ssim: json_to_index["partOf"],
      projection_ssim: json_to_index["projection"], # replaced by projection_tesim
      publicationPlace_ssim: json_to_index["creationPlace"],
      publicationPlace_tesim: json_to_index["creationPlace"],
      recordType_ssim: json_to_index["recordType"], # replaced by recordType_ssi
      references_ssim: json_to_index["preferredCitation"], # replaced by references_tesim
      references_tesim: json_to_index["preferredCitation"], # replaced by preferredCitation_tesim
      scale_ssim: json_to_index["scale"], # replaced by scale_tesim
      sourceCreated_ssim: json_to_index["sourceCreated"], # replaced by sourceCreated_tesim
      sourceDate_ssim: json_to_index["sourceDate"], # replaced by sourceDate_tesim
      sourceEdition_ssim: json_to_index["sourceEdition"], # replaced by sourceEdition_tesim
      sourceNote_ssim: json_to_index["sourceNote"], # replaced by sourceNote_tesim
      sourceTitle_ssim: json_to_index["sourceTitle"], # repleaced by sourceTitle_tesim
      subject_topic_tsim: json_to_index["subjectTopic"], # replaced by subjectTopic_tesim and subjectTopic_ssim
      title_tsim: json_to_index["title"] # replaced by title_tesim
    }.delete_if { |_k, v| v.nil? }
  end

  def expand_date_structured(date_structured)
    return nil unless date_structured&.is_a?(Array)
    date_structured.each_with_object(SortedSet.new) do |date, set|
      if date.include? '/'
        dates = date.split('/')
        if dates.count == 2
          date1 = dates[0].to_i
          date2 = dates[1].to_i
          date2 = Time.now.utc.year if date2 == 9999
          (date1..date2).each { |range_date| set << range_date }
        end
      else
        set << date.to_i
      end
    end.to_a
  end
end
