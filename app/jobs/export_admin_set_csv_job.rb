# frozen_string_literal: true

class ExportAdminSetCsvJob < ApplicationJob
  queue_as :default

  def default_priority
    -100
  end

  def perform(batch_process)
    batch_process.parent_output_csv
  end
end
