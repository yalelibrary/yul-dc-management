# frozen_string_literal: true
class AdminSet < ApplicationRecord
  validates :key, presence: true
  validates :label, presence: true
  validates :homepage, presence: true
  validates :homepage, format: URI.regexp(%w[http https])
end
