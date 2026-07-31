# frozen_string_literal: true

class Structure < ApplicationRecord
  PRESERVICA = 'preservica'
  EDITOR = 'editor'

  has_many :structures, dependent: :destroy
  belongs_to :parent_object, foreign_key: 'parent_object_oid'

  scope :preservica_built, -> { where(source: PRESERVICA) }
  scope :editor_built, -> { where(source: EDITOR) }
end
