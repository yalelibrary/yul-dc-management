class BatchProcessEvent < ApplicationRecord
  belongs_to :batch_process
  belongs_to :parent_object, foreign_key: 'parent_object_oid', class_name: "ParentObject"
end
