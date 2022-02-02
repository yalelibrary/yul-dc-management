# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SolrIndexable, type: :model, solr: true do
  let(:solr_indexable) { ParentObject.new(admin_set: FactoryBot.create(:admin_set)) }

  before do
    stub_ptiffs_and_manifests
  end

  describe "valid solr document" do
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
    # rubocop:enable Lint/ParenthesesAsGroupedExpression
  end

  describe "invalid solr document" do
    before do
      allow(solr_indexable).to receive(:manifest_completed?).and_return(false)
    end

    it "removes the incomplete record from solr" do
      # TODO: ensure it is indexed to solr and confirm it's presence before confirming it has been removed
      solr_document = solr_indexable.to_solr({})
      expect(solr_document[:incomplete]).to eq true
      parent_response = solr.get 'select', params: { q: 'type_ssi:parent' }
      expect(parent_response["response"]["numFound"]).to eq 0
      child_response = solr.get 'select', params: { q: 'type_ssi:child' }
      expect(child_response["response"]["numFound"]).to eq 0
    end
  end
end
