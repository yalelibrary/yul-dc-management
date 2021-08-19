# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "admin_sets/show", type: :view do
  include Devise::Test::ControllerHelpers
  before do
    @admin_set = assign(:admin_set, AdminSet.create!(
                                      key: "Key",
                                      label: "Label",
                                      homepage: "http://test.com",
                                      summary: "summary"
                                    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Key/)
    expect(rendered).to match(/Label/)
    expect(rendered).to match(/http:\/\/test.com/)
    expect(rendered).to match(/summary/)
  end
end
