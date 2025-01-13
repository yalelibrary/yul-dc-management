# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "problem_report_mailer/problem_report_email", type: :view do
  let(:problem_report) { FactoryBot.create(:problem_report) }
  it "renders a warning about problem count" do
    problem_report.problem_child_count = 1001
    @problem_report = problem_report
    render
    expect(rendered).to have_content "Warning: Only the first 1000 problem children will be in the spreadsheet"
  end

  it "renders a warning about problem count" do
    problem_report.problem_child_count = 999
    @problem_report = problem_report
    render
    expect(rendered).not_to have_content "Warning: Only the first 1000 problem children will be in the spreadsheet"
  end
end
