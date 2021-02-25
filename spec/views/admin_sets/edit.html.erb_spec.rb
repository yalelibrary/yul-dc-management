# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "admin_sets/edit", type: :view do
  let(:admin_set) do
    AdminSet.create!(
      key: "MyString",
      label: "MyString",
      homepage: "MyString"
    )
  end

  before do
    @admin_set = admin_set
  end

  it "renders the edit admin_set form" do
    render

    assert_select "form[action=?][method=?]", admin_set_path(admin_set), "post" do
      assert_select "input[name=?]", "admin_set[key]"

      assert_select "input[name=?]", "admin_set[label]"

      assert_select "input[name=?]", "admin_set[homepage]"
    end
  end
end
