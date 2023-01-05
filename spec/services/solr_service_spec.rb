# frozen_string_literal: true
require 'rails_helper'

RSpec.describe SolrService, solr: true, prep_metadata_sources: true do
  index_analyzer = {
    'tokenizer': {
      class: 'solr.WhitespaceTokenizerFactory'
    },
    'filters': [
      { class: 'solr.WordDelimiterGraphFilterFactory' },
      { class: 'solr.FlattenGraphFilterFactory' }
    ]
  }
  query_analyzer = {
    'tokenizer': {
      class: 'solr.WhitespaceTokenizerFactory'
    },
    'filters': [
      { class: 'solr.WordDelimiterGraphFilterFactory' }
    ]
  }

  it 'can trigger an error when field is already in schema' do
    expect do
      SolrService.add_field_type('text_ocr', 'solr.TextField', index_analyzer, query_analyzer)
    end.to raise_error(Faraday::BadRequestError)
  end
  it 'can replace a field type' do
    expect(SolrService.replace_field_type('text_ocr', 'solr.TextField', index_analyzer, query_analyzer).success?).to eq true
  end
  it 'can trigger an error when a dynamic field type is already in schema' do
    expect do
      SolrService.add_dynamic_field('*_wstsim', 'text_ocr', true, true, true)
    end.to raise_error(Faraday::BadRequestError)
  end
  it 'can replace a dynamic field type' do
    expect(SolrService.replace_dynamic_field('*_wstsim', 'text_ocr', true, true, true).success?).to eq true
  end
end
