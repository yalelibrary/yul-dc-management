# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrIndexable, type: :model do
  let(:solr_indexable) { ParentObject.new }

  before do
    allow(solr_indexable).to receive(:manifest_completed?).and_return(true)
  end

  it "indexes language and languageCode" do
    solr_document = solr_indexable.to_solr('languageCode' => ['eng'], 'language' => ['English'])
    expect(solr_document[:languageCode_ssim]).to eq(['eng'])
    expect(solr_document[:language_ssim]).to eq(['English'])
  end

  it "indexes the project identifier" do
    solr_document = solr_indexable.to_solr('digitization_note' => ['digitization note'])
    expect(solr_document[:digitization_note_tesi]).to eq(['digitization note'])
  end
end
