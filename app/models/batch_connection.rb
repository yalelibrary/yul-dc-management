# frozen_string_literal: true

class BatchConnection < ApplicationRecord
  include Statable
  belongs_to :batch_process
  belongs_to :connectable, polymorphic: true

  def note_records(batch_process_id)
    Notification.where(["params->>'batch_process_id' = :id and
    params->>'#{connectable_type.underscore}_id' = :oid", { id: batch_process_id.to_s, oid:
      connectable_id.to_s }])
  end
end
