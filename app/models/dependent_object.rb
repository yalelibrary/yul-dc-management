# frozen_string_literal: true

class DependentObject < ApplicationRecord
  belongs_to :parent_object
end
