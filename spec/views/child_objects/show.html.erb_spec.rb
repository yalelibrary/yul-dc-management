# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "child_objects/show", type: :view, prep_metadata_sources: true do
  include Devise::Test::ControllerHelpers
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2004628") }

  before do
    stub_ptiffs
    stub_metadata_cloud("2004628")
    parent_object
    @child_object = assign(:child_object, ChildObject.create!(
                                            oid: 10,
                                            caption: "Caption",
                                            label: "1v",
                                            width: 2591,
                                            height: 4056,
                                            order: 4,
                                            parent_object_oid: "2004628"
                                          ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Oid/)
    expect(rendered).to match(/Caption/)
    expect(rendered).to match(/1v/)
    expect(rendered).to match(/2591/)
    expect(rendered).to match(/4056/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(//)
  end
end
