# frozen_string_literal: true

class BatchConnection < ApplicationRecord
  include Statable
  belongs_to :batch_process
  belongs_to :connectable, polymorphic: true
  has_many :ingest_events, dependent: nil

  def update_status
    self.status = connectable.status_for_batch_process(batch_process)
  end

  def update_status!
    update_status && save!
  end

  def batch_connections_for(_batch_process)
    [self]
  end
end
