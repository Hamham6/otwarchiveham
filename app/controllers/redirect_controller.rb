class RedirectController < ApplicationController
  before_action :check_permission, only: [:show]

  def check_permission
    return if params[:original_url].present?
    return if user_has_roles?(Admin::REDIRECT_ACCESS_ROLES) || current_user.is_archivist?

    current_user.logged_in_as_admin? ? redirect_to(admin_only_access_denied) : redirect_to(access_denied)
  end

  def index
    do_redirect
  end

  def do_redirect
    url = params[:original_url]
    if url.blank?
      flash[:error] = t(".no_url")
    else
      @work = Work.find_by_url(url)
      if @work
        flash[:notice] = t(".redirected_from", original_url: url)
        redirect_to work_path(@work) and return
      else
        flash[:error] = t(".no_work_found")
      end
    end
    redirect_to redirect_path
  end

  def show
    redirect_to action: :do_redirect, original_url: params[:original_url] and return
  end
end
