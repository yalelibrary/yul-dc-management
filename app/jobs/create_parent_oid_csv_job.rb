# frozen_string_literal: true

class CreateParentOidCsvJob < ApplicationJob
  queue_as :default

  def default_priority
    50
  end

  def perform(batch_process, *admin_set_id)
    batch_process.parent_output_csv(*admin_set_id)
  end
end
