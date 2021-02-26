# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "admin_sets/index", type: :view do
  it "renders admin_sets table" do
    render
    assert_select "tr>th", text: "Key".to_s, count: 1
    assert_select "tr>th", text: "Label".to_s, count: 1
    assert_select "tr>th", text: "Homepage".to_s, count: 1
  end
end
