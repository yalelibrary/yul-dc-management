require 'rails_helper'

RSpec.describe "batch_process_events/index", type: :view do
  before(:each) do
    assign(:batch_process_events, [
      BatchProcessEvent.create!(
        batch_process: nil,
        parent_object: nil
      ),
      BatchProcessEvent.create!(
        batch_process: nil,
        parent_object: nil
      )
    ])
  end

  it "renders a list of batch_process_events" do
    render
    assert_select "tr>td", text: nil.to_s, count: 2
    assert_select "tr>td", text: nil.to_s, count: 2
  end
end
