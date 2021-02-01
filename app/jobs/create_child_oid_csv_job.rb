# frozen_string_literal: true

# TODO: this is a onetime thing for a data migration
# it can be removed after 3/1/2021
class CreateChildOidCsvJob < ApplicationJob
  queue_as :default

  def default_priority
    -100
  end

  def perform(batch_process)
    batch_process.output_csv
  end
end
