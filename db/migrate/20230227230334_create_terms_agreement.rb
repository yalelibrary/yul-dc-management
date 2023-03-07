class CreateTermsAgreement < ActiveRecord::Migration[6.1]
  def change
    create_table :terms_agreements do |t|
      t.timestamp :agreement_ts
      t.timestamps
    end
    add_reference :terms_agreements, :permission_set_term, index: true
    add_reference :terms_agreements, :permission_request_user, index: true
  end
end
