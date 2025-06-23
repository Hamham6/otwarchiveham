# frozen_string_literal: true

require "spec_helper"

describe RedirectController do
  include RedirectExpectationHelper
  include LoginMacros
  let(:original_url) { "http://www.example.com" }
  let(:imported_work) { create(:work, imported_from_url: original_url) }

  shared_examples "an action logged-out users cannot access" do
    it "redirects with an error" do
      subject

      it_redirects_to_with_error(new_user_session_path, "Sorry, you don't have permission to access the page you were trying to reach. Please log in.")
    end
  end

  shared_examples "an action logged-in users with no role cannot access" do
    before { fake_login_known_user(user) }
    let(:user) { create(:user) }

    it "redirects with an error" do
      subject

      it_redirects_to_with_error(user_path(user), "Sorry, you don't have permission to access the page you were trying to reach.")
    end
  end

  describe "GET #do_redirect" do
    authorized_admin_roles = %w[superadmin open_doors]

    authorized_admin_roles.each do |role|
      context "when logged in as an admin with role #{role}" do
        before do
          fake_login_admin(admin)
          imported_work
        end
        let(:admin) { create(:admin, roles: [role]) }

        it "errors with no original_url param" do
          get :do_redirect

          it_redirects_to_with_error(redirect_path, "What URL did you want to look up?")
        end

        it "redirects to work with an original_url param for an existing work" do
          get :do_redirect, params: { original_url: original_url }

          it_redirects_to_with_notice(work_path(imported_work), "You have been redirected here from #{original_url}. Please update the original link if possible!")
        end

        it "errors with an original_url param for a nonexistent work" do
          get :do_redirect, params: { original_url: "nonexistent_work" }

          it_redirects_to_with_error(redirect_path, "We could not find a work imported from that URL, sorry!")
        end
      end
    end

    context "when logged in as a user with the archivist role" do
      before { fake_login_known_user(user) }
      let(:user) { create(:user, roles: [archivist]) }

      it "errors with no original_url param" do
        get :do_redirect

        it_redirects_to_with_error(redirect_path, "What URL did you want to look up?")
      end

      it "redirects to work with an original_url param for an existing work" do
        get :do_redirect, params: { original_url: original_url }

        it_redirects_to_with_notice(work_path(imported_work), "You have been redirected here from #{original_url}. Please update the original link if possible!")
      end

      it "errors with an original_url param for a nonexistent work" do
        get :do_redirect, params: { original_url: "nonexistent_work" }

        it_redirects_to_with_error(redirect_path, "We could not find a work imported from that URL, sorry!")
      end
    end
  end

  describe "GET #show" do
    authorized_admin_roles = %w[superadmin open_doors]
    subject { get :show }

    it_behaves_like "an action only authorized admins can access", authorized_roles: authorized_admin_roles #redirects to new_user_session_path
    it_behaves_like "an action logged-in users with no role cannot access"
    it_behaves_like "an action logged-out users cannot access"

    it "shows the redirect page when logged in as a users with the archivist role" do
      create(:user, roles: [archivist])
      fake_login_known_user(user)
      subject

      success
    end

    it "redirects when there is an original_url param" do
      get :show, params: { original_url: "something" }

      it_redirects_to(action: :do_redirect, params: { original_url: "something" })
    end
  end
end
