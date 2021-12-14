# frozen_string_literal: true

module SolrIndexable
  extend ActiveSupport::Concern
  class_methods do
    def solr_index
      SolrReindexAllJob.perform_later
    end
  end

  def solr_index
    begin
      if self&.redirect_to.present?
        indexable = to_solr(json_to_index = nil)
      else
        indexable, child_solr_documents = to_solr_full_text
      end
      return unless indexable.present?
      solr = SolrService.connection
      solr.add([indexable])
      solr.add(child_solr_documents) unless child_solr_documents.nil?
      result = solr.commit
      if (result&.[]("responseHeader")&.[]("status"))&.zero?
        processing_event("Solr index updated", "solr-indexed")
      else
        processing_event("Solr index after manifest generation failed", "failed")
      end
    rescue => e
      processing_event("Solr indexing failed due to #{e.message}", "failed")
      raise # this reraises the error after we document it
    end
    result
  end

  def solr_delete
    solr = SolrService.connection
    solr.delete_by_id(oid.to_s)
    solr.commit
  end

  def solr_index_job
    current_batch_connection&.save
    SolrIndexJob.perform_later(self, current_batch_process, current_batch_connection) if queued_solr_index_jobs.empty?
  end

  def to_solr(json_to_index = nil)
    if self.redirect_to.present?
      {
        id: self&.oid, 
        visibility_ssi: "Redirect",
        redirect_to_tesi: self&.redirect_to 
      }
    else
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
        ancestorDisplayStrings_tesim: json_to_index["ancestorDisplayStrings"],
        ancestorTitles_tesim: generate_ancestor_title(json_to_index["ancestorTitles"]),
        ancestor_titles_hierarchy_ssim: ancestor_structure(generate_ancestor_title(json_to_index["ancestorTitles"])),
        archivalSort_ssi: json_to_index["archivalSort"],
        archiveSpaceUri_ssi: aspace_uri,
        box_ssim: extract_container_information(json_to_index),
        callNumber_ssim: json_to_index["callNumber"],
        callNumber_tesim: json_to_index["callNumber"],
        caption_tesim: child_captions,
        child_oids_ssim: child_oids,
        collection_title_ssi: json_to_index["ancestorTitles"]&.[](-2),
        collectionId_ssim: json_to_index["collectionId"],
        collectionId_tesim: json_to_index["collectionId"],
        containerGrouping_ssim: extract_container_information(json_to_index),
        containerGrouping_tesim: extract_container_information(json_to_index),
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
        digitization_note_tesi: generate_digitization_note(json_to_index["digitization_note"]),
        edition_ssim: json_to_index["edition"],
        extent_ssim: json_to_index["extent"],
        extentOfDigitization_ssim: extent_of_digitization,
        findingAid_ssim: json_to_index["findingAid"],
        folder_ssim: json_to_index["folder"],
        format: json_to_index["format"],
        format_tesim: json_to_index["format"],
        genre_ssim: json_to_index["genre"],
        genre_tesim: json_to_index["genre"],
        geoSubject_ssim: json_to_index["geoSubject"],
        hashed_id_ssi: generate_hash,
        has_fulltext_ssi: "No",
        identifierMfhd_ssim: json_to_index["identifierMfhd"],
        imageCount_isi: child_object_count,
        indexedBy_tsim: json_to_index["indexedBy"],
        label_tesim: child_labels,
        language_ssim: json_to_index["language"],
        languageCode_ssim: json_to_index["languageCode"],
        localRecordNumber_ssim: json_to_index["localRecordNumber"],
        material_tesim: json_to_index["material"],
        number_of_pages_ss: json_to_index["numberOfPages"],
        oid_ssi: oid,
        orbisBarcode_ssi: barcode,
        orbisBibId_ssi: bib, # may change to orbisBibId
        partOf_tesim: json_to_index["partOf"],
        preferredCitation_tesim: json_to_index["preferredCitation"],
        project_identifier_tesi: generate_pid(json_to_index["project_identifier"]),
        projection_tesim: json_to_index["projection"],
        public_bsi: true, # TEMPORARY, makes everything public
        publisher_tesim: json_to_index["publisher"],
        publisher_ssim: json_to_index["publisher"],
        recordType_ssi: json_to_index["recordType"],
        relatedResourceOnline_ssim: json_to_index["relatedResourceOnline"],
        repository_ssi: self&.admin_set&.label,
        repository_ssim: self&.admin_set&.label,
        resourceType_ssim: json_to_index["itemType"],
        resourceType_tesim: json_to_index["itemType"],
        resourceVersionOnline_ssim: json_to_index["resourceVersionOnline"],
        rights_ssim: rights_statement,
        rights_tesim: rights_statement,
        scale_tesim: json_to_index["scale"],
        series_ssi: json_to_index["series"],
        series_sort_ssi: series_sort(json_to_index),
        source_ssim: json_to_index["source"], # refers to source of metadata, e.g. Ladybird, Voyager, etc.
        sourceCreated_tesim: json_to_index["sourceCreated"],
        sourceDate_tesim: json_to_index["sourceDate"],
        sourceEdition_tesim: json_to_index["sourceEdition"], # Not currently in Blacklight application
        sourceNote_tesim: json_to_index["sourceNote"],
        sourceTitle_tesim: json_to_index["sourceTitle"],
        sourceCreator_tesim: json_to_index["sourceCreator"],
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
        viewing_hint_ssi: display_layout,
        visibility_ssi: visibility,
        type_ssi: 'parent'
      }.delete_if { |_k, v| v.blank? } # Delete nil, [], and empty string values
    end
  end

  def to_solr_full_text(json_to_index = nil)
    solr_document = to_solr(json_to_index)
    child_solr_documents = child_object_solr_documents
    solr_document[:fulltext_tesim] = child_solr_documents.map { |child_solr_document| child_solr_document.try(:[], :child_fulltext_tesim) } unless solr_document.nil? || child_solr_documents.nil?
    solr_document = append_full_text_status(solr_document)

    [solr_document, child_solr_documents]
  end

  def child_object_solr_documents
    if full_text?
      full_text_array = child_objects.map do |child_object|
        child_object_full_text = S3Service.download_full_text(child_object.remote_ocr_path)

        child_object_to_solr(child_object, child_object_full_text) unless child_object_full_text.nil?
      end
      return full_text_array.compact
    end
    nil
  end

  def child_object_to_solr(child_object, child_object_full_text)
    parent_object = child_object.parent_object
    {
      id: child_object.oid,
      parent_ssi: parent_object.oid,
      child_fulltext_tesim: child_object_full_text,
      child_fulltext_wstsim: child_object_full_text,
      type_ssi: 'child'
    }
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

  def append_full_text_status(solr_document)
    return unless solr_document
    solr_document[:has_fulltext_ssi] = extent_of_full_text

    solr_document
  end

  def ancestor_structure(ancestor_title)
    # Building the hierarchy structure
    return nil unless ancestor_title&.is_a?(Array)
    anc_struct = []
    ancestor_title = ancestor_title.reverse
    arr_size = 0
    prev_string = ""
    ancestor_title.each do |anc|
      prev_string += (ancestor_title[arr_size - 1]).to_s + " > " unless arr_size.zero?
      anc = prev_string + anc + " > "
      formatted = anc[0...-3]
      anc_struct.push(formatted)
      arr_size += 1
    end
    anc_struct
  end

  def generate_hash
    Digest::MD5.hexdigest oid.to_s
  end

  def generate_pid(project_identifier)
    project_identifier.presence || self&.project_identifier || nil
  end

  def generate_digitization_note(digitization_note)
    digitization_note.presence || self&.digitization_note || nil
  end

  # not ASpace records will use the repository value
  def generate_ancestor_title(ancestor_title)
    ancestor_title.presence || [self&.admin_set&.label] || nil
  end

  def series_sort(json_to_index)
    return nil unless json_to_index['series'].present? && json_to_index['archivalSort']
    # only get the first portion of the sort, that represents the series sort value.
    sort = json_to_index['archivalSort'].split(".")[0]
    "#{sort}|#{json_to_index['series']}"
  end
end
