require 'rails_helper'

RSpec.describe "batch_process_events/new", type: :view do
  before(:each) do
    assign(:batch_process_event, BatchProcessEvent.new(
      batch_process: nil,
      parent_object: nil
    ))
  end

  it "renders new batch_process_event form" do
    render

    assert_select "form[action=?][method=?]", batch_process_events_path, "post" do

      assert_select "input[name=?]", "batch_process_event[batch_process_id]"

      assert_select "input[name=?]", "batch_process_event[parent_object_id]"
    end
  end
end
