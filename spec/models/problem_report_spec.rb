# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProblemReport, type: :model do
  let(:problem_report) { FactoryBot.create(:problem_report) }
  it "has all expected fields" do
    expect(problem_report.child_count).to eq 1
    expect(problem_report.parent_count).to eq 1
    expect(problem_report.problem_parent_count).to eq 1
    expect(problem_report.problem_child_count).to eq 1
  end
end
