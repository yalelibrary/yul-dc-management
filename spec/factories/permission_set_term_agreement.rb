# frozen_string_literal: true

FactoryBot.define do
  factory :term_agreement, class: OpenWithPermission::TermsAgreement do
    agreement_ts { "2022-11-08 15:33:30" }
  end
end
