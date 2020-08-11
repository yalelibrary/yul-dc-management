require 'rails_helper'

RSpec.describe "child_objects/show", type: :view do
  before(:each) do
    @child_object = assign(:child_object, ChildObject.create!(
      child_oid: "Child Oid",
      caption: "Caption",
      width: 2,
      height: 3,
      order: 4,
      parent_object: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Child Oid/)
    expect(rendered).to match(/Caption/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(//)
  end
end
