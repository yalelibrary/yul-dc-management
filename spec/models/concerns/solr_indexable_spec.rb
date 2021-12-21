# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrIndexable, type: :model do
  let(:solr_indexable) { ParentObject.new(admin_set: FactoryBot.create(:admin_set)) }

  before do
    allow(solr_indexable).to receive(:manifest_completed?).and_return(true)
  end

  it "indexes language and languageCode" do
    solr_document = solr_indexable.to_solr('languageCode' => ['eng'], 'language' => ['English'])
    expect(solr_document[:languageCode_ssim]).to eq(['eng'])
    expect(solr_document[:language_ssim]).to eq(['English'])
  end

  it "indexes the project identifier" do
    solr_document = solr_indexable.to_solr('project_identifier' => ['project id'])
    expect(solr_document[:project_identifier_tesi]).to eq(['project id'])
  end

  it "indexes the digitization note" do
    solr_document = solr_indexable.to_solr('digitization_note' => ['digitization note'])
    expect(solr_document[:digitization_note_tesi]).to eq(['digitization note'])
  end

  it "indexes the ancestor titles" do
    solr_document = solr_indexable.to_solr('ancestorTitles' => ['ancestor title'])
    expect(solr_document[:ancestorTitles_tesim]).to eq(['ancestor title'])
  end

  it "indexes the subject headings" do
    solr_document = solr_indexable.to_solr('subjectHeading' => ['Test > Test2', 'Two > Three > Four'])
    expect(solr_document[:subjectHeading_ssim]).to eq(['Test > Test2', 'Two > Three > Four'])
    expect(solr_document[:subjectHeadingFacet_ssim]).to eq(['Test', 'Test > Test2', 'Two', 'Two > Three', 'Two > Three > Four'])
  end
end
