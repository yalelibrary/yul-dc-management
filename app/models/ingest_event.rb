# frozen_string_literal: true

class IngestEvent < ApplicationRecord
  belongs_to :batch_connection
end
