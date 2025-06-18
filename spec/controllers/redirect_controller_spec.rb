# frozen_string_literal: true

require "spec-helper"

describe RedirectController do
  let(:original_url) { "http://www.example.com" }
  let(:imported_work) { create(:work, imported_from_url: original_url) }

  shared_examples "an action only authorized admins and users with the archivist role can access" do |authorized_admin_roles:|
    it_behaves_like "an action only authorized admins can access", authorized_roles: authorized_admin_roles
    it_behaves_like "an action logged-in users without roles can't access"
    it_behaves_like "an action logged-out users cannot access"

    context "when logged in as a user with the archivist role" do
      before { fake_login_known_user(user) }
      let(:user) { create(:user, roles: ["archivist"]) }

      it "succeeds" do
        subject

        success
      end
    end
  end

  describe "GET #index" do
    authorized_admin_roles = Admin::REDIRECT_ACCESS_ROLES

    it "restricts access when there is no original_url param" do
      subject { get :index }

      it_behaves_like "an action only authorized admins and users with the archivist role can access", authorized_admin_roles: authorized_admin_roles
    end

    it "redirects when there is an original_url param" do
      expect do
        get :index, params: { original_url: "something" }
      end.to redirect_to(action: :do_redirect, params: { original_url: "something" })
    end
  end

  describe "GET #do_redirect" do
    authorized_admin_roles = Admin::REDIRECT_ACCESS_ROLES

    authorized_roles.each do |role|
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
      let(:user) { create(:user, roles: ["archivist"]) }

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

    #it_behaves_like "an action unauthorized admins cannot access", authorized_roles: authorized_admin_roles
    it_behaves_like "an action logged-in users without roles cannot access"
    it_behaves_like "an action logged-out users cannot access"
  end

  describe "GET #show" do
    authorized_admin_roles = Admin::REDIRECT_ACCESS_ROLES

    it "restricts access when there is no original_url param" do
      subject { get :show }

      it_behaves_like "an action only authorized admins and users with the archivist role can access", authorized_admin_roles: authorized_admin_roles
    end

    it "redirects when there is an original_url param" do
      expect do
        get :show, params: { original_url: "something" }
      end.to redirect_to(action: :do_redirect, params: { original_url: "something" })
    end
  end
end
