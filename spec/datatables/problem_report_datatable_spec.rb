# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProblemReportDatatable, type: :datatable, prep_metadata_sources: true do
  columns = ['status', 'parent_count', 'child_count', 'problem_parent_count', 'problem_child_count', 'date', 'report']
  let(:problem_report) { FactoryBot.create(:problem_report) }

  describe 'admin set data tables' do
    it 'can handle an empty model set' do
      output = ProblemReportDatatable.new(datatable_sample_params(columns)).data

      expect(output).to eq([])
    end

    it 'can handle a populated set' do
      output = ProblemReportDatatable.new(datatable_sample_params(columns),
                                          view_context: problem_report_datatable_view_mock(
                                            problem_report.status,
                                            problem_report.parent_count,
                                            problem_report.child_count,
                                            problem_report.problem_parent_count,
                                            problem_report.problem_child_count,
                                            problem_report.created_at,
                                            problem_report.id
                                          )).data

      expect(output).to include(

        status: problem_report.status,
        parent_count: problem_report.parent_count,
        child_count: problem_report.child_count,
        problem_parent_count: problem_report.problem_parent_count,
        problem_child_count: problem_report.problem_child_count,
        date: problem_report.created_at,
        report: 'n/a'
      )
    end
  end
end
