# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "admin_sets/show", type: :view do
  before do
    @admin_set = assign(:admin_set, AdminSet.create!(
                                      key: "Key",
                                      label: "Label",
                                      homepage: "Homepage",
                                      summary: "summary"
                                    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Key/)
    expect(rendered).to match(/Label/)
    expect(rendered).to match(/Homepage/)
    expect(rendered).to match(/summary/)
  end
end
