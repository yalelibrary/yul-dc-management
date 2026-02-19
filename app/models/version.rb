# frozen_string_literal: true

class Version < ApplicationRecord
  self.primary_key = :id
  default_scope -> { order("versions.created_at ASC, versions.id ASC") }
end
