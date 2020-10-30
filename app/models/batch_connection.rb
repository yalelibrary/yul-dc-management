# frozen_string_literal: true

class BatchConnection < ApplicationRecord
  belongs_to :batch_process
  belongs_to :connectable, polymorphic: true

  # def status
  #   ParentObject.find(connectable_id).status_for_batch_process(batch_process_id)
  # rescue ActiveRecord::RecordNotFound
  #   "Parent object deleted"
  # end
end
