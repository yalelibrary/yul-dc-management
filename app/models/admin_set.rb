# frozen_string_literal: true
class AdminSet < ApplicationRecord
  resourcify
  validates :key, presence: true
  validates :label, presence: true
  validates :homepage, presence: true
  validates :homepage, format: URI.regexp(%w[http https])
end
