# frozen_string_literal: true

class SolrIndexJob < ApplicationJob
  queue_as :default

  def perform(parent_object)
    parent_object.solr_index
  end
end
