# frozen_string_literal: true

# Log specs in through the app's own CAS sign-in (OmniAuth test mode) instead of Warden's login_as.
#
# Warden's login_as / Devise's sign_in push a callback onto a process-global queue that the next
# request to reach the app consumes. In CI the Capybara server runs in the same process as the specs,
# so a stray request could take a spec's login, and the spec's own request arrived logged out.
# Signing in through the app stores the login in that spec's own session cookie instead.
#
# These modules are prepended (see the RSpec.configure block below) so they win over
# Warden::Test::Helpers and Devise::Test::IntegrationHelpers, and existing call sites don't change.
module CasLoginHelper
  # Mocks CAS for the given user while the block runs, then restores the previous mock, which
  # spec/controllers/omniauth_callbacks_controller_spec.rb sets once at load time.
  def with_cas_mock_for(user)
    OmniAuth.config.test_mode = true
    previous_mock = OmniAuth.config.mock_auth[:cas]
    OmniAuth.config.mock_auth[:cas] = OmniAuth::AuthHash.new(provider: "cas", uid: user.uid)
    yield
  ensure
    OmniAuth.config.mock_auth[:cas] = previous_mock
  end
end

module SystemLoginHelper
  include CasLoginHelper

  def login_as(user, _opts = {})
    with_cas_mock_for(user) do
      visit root_path
      # Lets a spec switch users: sign the current user out first
      click_on("Sign Out") if page.has_link?("Sign Out", wait: 0)
      click_button("You must sign in")
      # Don't let the spec move on until the login has worked
      expect(page).to have_link("Sign Out")
    end
  end
  alias sign_in login_as
end

module RequestLoginHelper
  include CasLoginHelper

  def login_as(user, _opts = {})
    with_cas_mock_for(user) do
      post user_cas_omniauth_authorize_path
      follow_redirect!
      # Don't let the spec move on until the login has worked
      expect(session["warden.user.user.key"]).to be_present
    end
  end

  def sign_in(user, *_args, **_opts)
    login_as(user)
  end
end

RSpec.configure do |config|
  config.prepend SystemLoginHelper, type: :system
  config.prepend RequestLoginHelper, type: :request
end
