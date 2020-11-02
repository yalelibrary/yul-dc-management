# frozen_string_literal: true

class BatchConnection < ApplicationRecord
  belongs_to :batch_process
  belongs_to :connectable, polymorphic: true
end
