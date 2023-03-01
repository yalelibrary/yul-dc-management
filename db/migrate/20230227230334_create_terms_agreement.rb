class CreateTermsAgreement < ActiveRecord::Migration[6.1]
  def change
    create_table :terms_agreements do |t|
      t.timestamp :agreement_ts
      t.timestamps
    end
    add_reference :terms_agreements, :permission_set_terms, index: true
    add_reference :terms_agreements, :permission_request_users, index: true
    add_reference :permission_set_terms, :terms_agreements, index: true
    add_reference :permission_request_users, :terms_agreements, index: true
  end
end
