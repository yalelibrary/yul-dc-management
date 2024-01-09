# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "problem_reports/index", type: :view do
  it "renders a list of problem_reports" do
    render
    expect(rendered).to have_content "Problem Reports"
  end
end
