class CreateSolrOcrFieldType < ActiveRecord::Migration[6.0]
  def change
    # Solr 9 ships text_ocr and *_wstsim in its read-only schema, so skip when already present
    return if text_ocr_exists?

    indexAnalyzer = {
        "tokenizer": {
            class: "solr.WhitespaceTokenizerFactory"
        },
        "filters": [
            {class:"solr.WordDelimiterGraphFilterFactory"},
            {class:"solr.FlattenGraphFilterFactory"}
        ]
    }    
    queryAnalyzer = {
        "tokenizer": {
            class: "solr.WhitespaceTokenizerFactory"
        },
        "filters": [
            {class:"solr.WordDelimiterGraphFilterFactory"}
        ]        
    }    
    begin
      SolrService.add_field_type("text_ocr", "solr.TextField", indexAnalyzer, queryAnalyzer)
    rescue Faraday::BadRequestError
      # the field may have already been created, so update
      SolrService.replace_field_type("text_ocr", "solr.TextField", indexAnalyzer, queryAnalyzer)
    end
    begin
      SolrService.add_dynamic_field("*_wstsim", "text_ocr", true, true, true)
    rescue Faraday::BadRequestError
      # the field may have already been created, so update
      SolrService.replace_dynamic_field("*_wstsim", "text_ocr", true, true, true)
    end
  end

  def text_ocr_exists?
    SolrService.connection.connection.get('schema/fieldtypes/text_ocr').success?
  rescue Faraday::Error
    false
  end
end
