# frozen_string_literal: true

module JsonHelper
  # Note, only use this helper on trusted, known JSON sources, since we are declaring the output as html_safe
  def formatted_json(json)
    json = JSON.pretty_generate(json)
    html = CodeRay.scan(json, :json).div
    html.html_safe
  end
end
