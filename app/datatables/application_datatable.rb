# frozen_string_literal: true

class ApplicationDatatable < AjaxDatatablesRails::ActiveRecord
  self.nulls_last = true

  private

  def records_filtered_count
    return records_total_count unless searching?

    super
  end

  def searching?
    datatable.searchable? || search_columns.any?
  end
end
