# frozen_string_literal: true

class SolrIndexJob < ApplicationJob
  queue_as :default

  def default_priority
    -50
  end

  def perform(parent_object)
    parent_object.solr_index
  end
end
