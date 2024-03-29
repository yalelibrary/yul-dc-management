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

  it "indexes the digitization funding source" do
    solr_document = solr_indexable.to_solr('digitization_funding_source' => ['digitization funding source'])
    expect(solr_document[:digitization_funding_source_tesi]).to eq(['digitization funding source'])
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

  it "indexes the collect creators" do
    solr_document = solr_indexable.to_solr('ancestorCreator' => ['ancestor creator'])
    expect(solr_document[:collectionCreators_ssim]).to eq(['ancestor creator'])
  end
  # rubocop:disable Lint/ParenthesesAsGroupedExpression
  it "indexes the creators only" do
    solr_document = solr_indexable.to_solr ({ 'ancestorCreator' => ['ancestor creator'], 'creator' => ['creator', 'creators', 'creatorx'] })
    expect(solr_document[:creator_ssim]).to eq(['creator', 'creators', 'creatorx', 'ancestor creator'])
  end

  it "indexes the all the creators for the collect" do
    solr_document = solr_indexable.to_solr ({ 'ancestorCreator' => ['ancestor creator', 'ancestor creator king'], 'creator' => ['creator', 'creators', 'creatorx', 'ancestor creator king'] })
    expect(solr_document[:creator_ssim]).to eq(['creator', 'creators', 'creatorx', 'ancestor creator king', 'ancestor creator'])
    expect(solr_document[:collectionCreators_ssim]).to eq(['ancestor creator'])
  end

  it "distinguishes actual orbis ids from quicksearch ids" do
    solr_indexable.bib = "557744"
    solr_document = solr_indexable.to_solr ({ "notblank" => "value" })
    expect(solr_document[:orbisBibId_ssi]).to eq('557744')
    expect(solr_document[:quicksearchId_ssi]).to be_nil
    solr_indexable.bib = "b557744"
    solr_document = solr_indexable.to_solr ({ "notblank" => "value" })
    expect(solr_document[:orbisBibId_ssi]).to be_nil
    expect(solr_document[:quicksearchId_ssi]).to eq("b557744")
  end

  it "handles nil orbis ids" do
    solr_indexable.bib = nil
    solr_document = solr_indexable.to_solr ({ "notblank" => "value" })
    expect(solr_document[:orbisBibId_ssi]).to be_nil
    expect(solr_document[:quicksearchId_ssi]).to be_nil
  end
  # rubocop:enable Lint/ParenthesesAsGroupedExpression

  it "indexes coordinateDisplay" do
    solr_document = solr_indexable.to_solr("coordinate" => ["do not index"], "coordinateDisplay" => ["(N90, S90, E90, W90)"])
    expect(solr_document[:coordinateDisplay_ssim]).to eq(["(N90, S90, E90, W90)"])
  end

  it "indexes coordinate as coordinateDisplay if coordinateDisplay is nil" do
    solr_document = solr_indexable.to_solr("coordinate" => ["coordinate"], "coordinateDisplay" => nil)
    expect(solr_document[:coordinateDisplay_ssim]).to eq(["coordinate"])
  end

  it "indexes coordinate as coordinateDisplay if coordinateDisplay is an empty array" do
    solr_document = solr_indexable.to_solr("coordinate" => ["coordinate"], "coordinateDisplay" => [])
    expect(solr_document[:coordinateDisplay_ssim]).to eq(["coordinate"])
  end
end
