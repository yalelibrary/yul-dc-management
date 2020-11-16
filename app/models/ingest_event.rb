class IngestEvent < ApplicationRecord
  belongs_to :batch_process
  belongs_to :batch_connection
  belongs_to :user
end
