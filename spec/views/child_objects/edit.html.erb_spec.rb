# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "child_objects/edit", type: :view, prep_metadata_sources: true do
  let(:parent_object) { FactoryBot.create(:parent_object, oid: "2004628") }
  before do
    stub_metadata_cloud("2004628")
    parent_object
    parent_object_created = ParentObject.find_by(oid: "2004628")
    @child_object = assign(:child_object, ChildObject.create!(
                                            child_oid: "MyString",
                                            caption: "10v",
                                            width: 1,
                                            height: 1,
                                            order: 1,
                                            parent_object: parent_object_created
                                          ))
  end

  it "renders the edit child_object form" do
    render

    assert_select "form[action=?][method=?]", child_object_path(@child_object), "post" do
      assert_select "input[name=?]", "child_object[child_oid]"

      assert_select "input[name=?]", "child_object[caption]"

      assert_select "input[name=?]", "child_object[width]"

      assert_select "input[name=?]", "child_object[height]"

      assert_select "input[name=?]", "child_object[order]"

      assert_select "input[name=?]", "child_object[parent_object_id]"
    end
  end
end
