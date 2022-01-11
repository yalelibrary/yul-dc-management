# frozen_string_literal: true

module Redirectable
  extend ActiveSupport::Concern

  def redirect_check
    return unless redirect_to_previously_changed?
    self.visibility = 'Redirect'
    save
    setup_metadata_job
  end
end
