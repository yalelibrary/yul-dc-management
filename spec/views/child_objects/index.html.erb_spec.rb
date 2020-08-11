require 'rails_helper'

RSpec.describe "child_objects/index", type: :view do
  before(:each) do
    assign(:child_objects, [
      ChildObject.create!(
        child_oid: "Child Oid",
        caption: "Caption",
        width: 2,
        height: 3,
        order: 4,
        parent_object: nil
      ),
      ChildObject.create!(
        child_oid: "Child Oid",
        caption: "Caption",
        width: 2,
        height: 3,
        order: 4,
        parent_object: nil
      )
    ])
  end

  it "renders a list of child_objects" do
    render
    assert_select "tr>td", text: "Child Oid".to_s, count: 2
    assert_select "tr>td", text: "Caption".to_s, count: 2
    assert_select "tr>td", text: 2.to_s, count: 2
    assert_select "tr>td", text: 3.to_s, count: 2
    assert_select "tr>td", text: 4.to_s, count: 2
    assert_select "tr>td", text: nil.to_s, count: 2
  end
end
