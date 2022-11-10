# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PermissionRequest, type: :model do

  describe PermissionRequest do
    it { is_expected.to belong_to(:permission_set) }
    it { is_expected.to belong_to(:permission_request_user) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:parent_object) }
  end
  
end