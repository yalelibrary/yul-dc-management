# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "child_objects/index", type: :view, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2004628") }

  before do
    stub_metadata_cloud("2004628")
    parent_object
    assign(:child_objects, [
             ChildObject.create!(
               child_oid: 111,
               caption: "Caption",
               width: 2,
               height: 3,
               order: 4,
               parent_object_oid: "2004628"
             ),
             ChildObject.create!(
               child_oid: 222,
               caption: "Caption",
               width: 2,
               height: 3,
               order: 4,
               parent_object_oid: "2004628"
             )
           ])
  end

  it "renders a list of child_objects" do
    render
    assert_select "tr>td", text: 111.to_s, count: 1
    assert_select "tr>td", text: 222.to_s, count: 1
    assert_select "tr>td", text: "Caption".to_s, count: 2
    assert_select "tr>td", text: 2.to_s, count: 2
    assert_select "tr>td", text: 3.to_s, count: 2
    assert_select "tr>td", text: 4.to_s, count: 2
  end
end
