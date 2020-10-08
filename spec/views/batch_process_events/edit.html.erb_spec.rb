require 'rails_helper'

RSpec.describe "batch_process_events/edit", type: :view do
  before(:each) do
    @batch_process_event = assign(:batch_process_event, BatchProcessEvent.create!(
      batch_process: nil,
      parent_object: nil
    ))
  end

  it "renders the edit batch_process_event form" do
    render

    assert_select "form[action=?][method=?]", batch_process_event_path(@batch_process_event), "post" do

      assert_select "input[name=?]", "batch_process_event[batch_process_id]"

      assert_select "input[name=?]", "batch_process_event[parent_object_id]"
    end
  end
end
