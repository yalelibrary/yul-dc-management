# frozen_string_literal: true

class BatchConnection < ApplicationRecord
  belongs_to :batch_process
  belongs_to :connectable, polymorphic: true

  def child_object_count
    return unless connectable_type == "ParentObject"
    ParentObject.find(connectable_id)&.child_object_count
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
