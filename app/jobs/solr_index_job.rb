# frozen_string_literal: true

class SolrIndexJob < ApplicationJob
  queue_as :solr_index

  def default_priority
    -50
  end

  def perform(parent_object)
    parent_object.solr_index
  end
end
