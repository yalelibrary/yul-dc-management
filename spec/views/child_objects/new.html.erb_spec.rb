# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "child_objects/new", type: :view do
  before do
    assign(:child_object, ChildObject.new(
                            oid: 1,
                            caption: "MyString",
                            width: 1,
                            height: 1,
                            order: 1,
                            parent_object: nil
                          ))
  end

  it "renders new child_object form" do
    render

    assert_select "form[action=?][method=?]", child_objects_path, "post" do
      assert_select "input[name=?]", "child_object[oid]"

      assert_select "input[name=?]", "child_object[caption]"

      assert_select "input[name=?]", "child_object[width]"

      assert_select "input[name=?]", "child_object[height]"

      assert_select "input[name=?]", "child_object[order]"

      assert_select "input[name=?]", "child_object[parent_object_oid]"
    end
  end
end
