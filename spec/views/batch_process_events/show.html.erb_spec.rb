# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "batch_process_events/show", type: :view, prep_metadata_sources: true do
  before do
    @batch_process_event = assign(:batch_process_event, BatchProcessEvent.create!(
                                                          batch_process: FactoryBot.create(:batch_process),
                                                          parent_object: FactoryBot.create(:parent_object)
                                                        ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
