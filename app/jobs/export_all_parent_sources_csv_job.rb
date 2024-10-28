# frozen_string_literal: true

class ExportAllParentSourcesCsvJob < ApplicationJob
  queue_as :default

  def default_priority
    50
  end

  def perform(batch_process, sources)
    batch_process.export_all_parents_source_csv(sources)
  end
end
