# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "child_objects/show", type: :view, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2004628") }

  before do
    stub_metadata_cloud("2004628")
    parent_object
    @child_object = assign(:child_object, ChildObject.create!(
                                            child_oid: "Child Oid",
                                            caption: "Caption",
                                            width: 2,
                                            height: 3,
                                            order: 4,
                                            parent_object_oid: "2004628"
                                          ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Child oid/)
    expect(rendered).to match(/Caption/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(//)
  end
end
