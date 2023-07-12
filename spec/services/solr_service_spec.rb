# frozen_string_literal: true
require 'rails_helper'

RSpec.describe SolrService, solr: true do
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

  context 'copy field add remove' do
    around do |example|
      begin
        SolrService.delete_copy_field("test_field_tesim", "test_ssim")
      rescue
        nil # do nothing
      end
      example.run
      begin
        SolrService.delete_copy_field("test_field_tesim", "test_ssim")
      rescue
        nil # do nothing
      end
    end

    it 'can trigger an error when deleting a copy field that does not exist' do
      expect do
        SolrService.delete_copy_field("test_field_tesim", "test_ssim")
      end.to raise_error(Faraday::BadRequestError)
    end
    it 'can add a copy field' do
      expect(SolrService.get_file("managed-schema").body.include?('<copyField source="test_field_tesim" dest="test_ssim"/>')).to be_falsy
      expect(SolrService.add_copy_field("test_field_tesim", "test_ssim").success?).to eq true
      expect(SolrService.get_file("managed-schema").body.include?('<copyField source="test_field_tesim" dest="test_ssim"/>')).to be_truthy
      SolrService.delete_copy_field("test_field_tesim", "test_ssim")
    end
    it 'can delete a copy field after adding it' do
      SolrService.add_copy_field("test_field_tesim", "test_ssim")
      expect(SolrService.delete_copy_field("test_field_tesim", "test_ssim").success?).to eq true
    end
  end
end
