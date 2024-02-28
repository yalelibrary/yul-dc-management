# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "users/index", type: :view do
  it "displays the users datatable" do
    render

    expect(rendered).to have_css('#users-datatable')
  end
end
