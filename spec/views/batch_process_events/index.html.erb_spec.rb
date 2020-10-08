# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "batch_process_events/index", type: :view, prep_metadata_sources: true do
  before do
    assign(:batch_process_events, [
             BatchProcessEvent.create!(
               batch_process: FactoryBot.create(:batch_process),
               parent_object: FactoryBot.create(:parent_object)
             ),
             BatchProcessEvent.create!(
               batch_process: FactoryBot.create(:batch_process),
               parent_object: FactoryBot.create(:parent_object, oid: 2_030_006)
             )
           ])
  end

  it "renders a list of batch_process_events" do
    render
    assert_select "tr>td", text: 2_030_006.to_s, count: 1
    assert_select "tr>td", text: 2_004_628.to_s, count: 1
  end
end
