# frozen_string_literal: true

class SolrIndexJob < ApplicationJob
  queue_as :solr_index

  def default_priority
    -50
  end

  def perform(parent_object, current_batch_process = nil, current_batch_connection = parent_object.current_batch_connection)
    parent_object.current_batch_process = current_batch_process
    parent_object.current_batch_connection = current_batch_connection
    parent_object.solr_index
  end
end
