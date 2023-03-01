# frozen_string_literal: true

class TermsAgreement < ApplicationRecord
  belongs_to :permission_set_term
  belongs_to :permission_request_user

end