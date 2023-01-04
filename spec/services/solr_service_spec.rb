# frozen_string_literal: true
require "rails_helper"

RSpec.describe SolrService, solr: true do
  index_analyzer = {
    "tokenizer": {
      class: "solr.WhitespaceTokenizerFactory"
    },
    "filters": [
      { class: "solr.WordDelimiterGraphFilterFactory" },
      { class: "solr.FlattenGraphFilterFactory" }
    ]
  }
  query_analyzer = {
    "tokenizer": {
      class: "solr.WhitespaceTokenizerFactory"
    },
    "filters": [
      { class: "solr.WordDelimiterGraphFilterFactory" }
    ]
  }

  it 'can add a field type' do
    expect(SolrService).to receive(:add_field_type).once
    SolrService.add_field_type("text_ocr", "solr.TextField", index_analyzer, query_analyzer)
  end
  it 'can replace a field type' do
    expect(SolrService).to receive(:replace_field_type).once
    SolrService.replace_field_type("text_ocr", "solr.TextField", index_analyzer, query_analyzer)
  end
  it 'can add a dynamic field type' do
    expect(SolrService).to receive(:add_dynamic_field).once
    SolrService.add_dynamic_field("*_wstsim", "text_ocr", true, true, true)
  end
  it 'can replace a dynamic field type' do
    expect(SolrService).to receive(:replace_dynamic_field).once
    SolrService.replace_dynamic_field("*_wstsim", "text_ocr", true, true, true)
  end
end
