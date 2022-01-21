# frozen_string_literal: true
class AdminSet < ApplicationRecord
  resourcify
  validates :key, presence: true
  validates :label, presence: true
  validates :homepage, presence: true
  validates :homepage, format: URI.regexp(%w[http https])

  def add_viewer(user)
    remove_editor(user) if user.editor(self)
    user.add_role(:viewer, self)
  end

  def remove_viewer(user)
    user.remove_role(:viewer, self)
  end

  def add_editor(user)
    remove_viewer(user) if user.viewer(self)
    user.add_role(:editor, self)
  end

  def remove_editor(user)
    user.remove_role(:editor, self)
  end

  def preservica_credentials_verified
    valid_format?(ENV['PRESERVICA_CREDENTIALS']) ? true : false
  end

  def valid_format?(json)
    # valid JSON,
    parsed_json = JSON.parse(json) unless json.nil?

    # exists,
    if ENV['PRESERVICA_CREDENTIALS'].present? &&
       # contains admin set key,
       parsed_json.include?(key) &&
       # and key references username and password with not blank values
       parsed_json[key.to_s]['username'].present? &&
       parsed_json[key.to_s]['password'].present?
      return true
    else
      return false
    end
  rescue JSON::ParserError
    false
  end
end
