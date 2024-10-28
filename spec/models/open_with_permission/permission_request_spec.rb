# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenWithPermission::PermissionRequest, type: :model do
  describe OpenWithPermission::PermissionRequest do
    it { is_expected.to belong_to(:permission_set) }
    it { is_expected.to belong_to(:permission_request_user) }
    it { is_expected.to belong_to(:parent_object) }
    it { is_expected.to have_one(:user) }
  end
end
