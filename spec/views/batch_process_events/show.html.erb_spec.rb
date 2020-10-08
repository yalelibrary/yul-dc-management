require 'rails_helper'

RSpec.describe "batch_process_events/show", type: :view do
  before(:each) do
    @batch_process_event = assign(:batch_process_event, BatchProcessEvent.create!(
      batch_process: nil,
      parent_object: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
