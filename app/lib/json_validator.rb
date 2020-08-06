# frozen_string_literal: true
# Inspired by https://gist.github.com/ascendbruce/7070951 on 8/5/2020

class JsonValidator
  def self.valid?(value)
    result = JSON.parse(value)

    result.is_a?(Hash) || result.is_a?(Array)
  rescue JSON::ParserError, TypeError
    false
  end
end
