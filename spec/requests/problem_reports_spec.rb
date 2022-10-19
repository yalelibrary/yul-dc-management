# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "/problem_reports", type: :request do
  let(:sysadmin_user) { FactoryBot.create(:sysadmin_user, uid: 'johnsmith2530') }
  let(:user) { FactoryBot.create(:user, uid: 'terrysmith2530') }

  let(:valid_attributes) do
    {
      id: 1,
      status: "Queued"
    }
  end
  describe 'with sys admin logged in' do
    before do
      login_as sysadmin_user
    end

    describe "GET /index" do
      it "renders a successful response" do
        ProblemReport.create! valid_attributes
        get problem_reports_url
        expect(response).to be_successful
      end
    end

    describe "POST /" do
      it "renders a successful response" do
        post problem_reports_path
        expect(response).to redirect_to(problem_reports_url)
      end
    end

    describe "POST / with queue_recurring" do
      it "renders a successful response" do
        post problem_reports_path(queue_recurring: "true")
        expect(response).to redirect_to(problem_reports_url)
      end
    end
  end

  describe 'with regular user logged in' do
    before do
      login_as user
    end

    describe "GET /index" do
      it "returns an unauthorized response" do
        ProblemReport.create! valid_attributes
        get problem_reports_url
        expect(response).to be_unauthorized
      end
    end

    describe "POST /" do
      it "returns an unauthorized response" do
        post problem_reports_path
        expect(response).to be_unauthorized
      end
    end
  end
end
