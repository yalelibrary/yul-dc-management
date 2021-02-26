# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "admin_sets/new", type: :view do
  before do
    assign(:admin_set, AdminSet.new(
                         key: "MyString",
                         label: "MyString",
                         homepage: "http://test.com"
                       ))
  end

  it "renders new admin_set form" do
    render

    assert_select "form[action=?][method=?]", admin_sets_path, "post" do
      assert_select "input[name=?]", "admin_set[key]"

      assert_select "input[name=?]", "admin_set[label]"

      assert_select "input[name=?]", "admin_set[homepage]"
    end
  end
end
