# frozen_string_literal: true

class OpenWithPermission::TermsAgreement < ApplicationRecord
  belongs_to :permission_set_term
  belongs_to :permission_request_user
end
