class RedirectController < ApplicationController
  before_action :check_permission, only: [:show]

  def check_permission
    return if params[:original_url].present?
    if logged_in_as_admin?
      (admin_only_access_denied and return) unless user_has_roles?(Admin::REDIRECT_ACCESS_ROLES)
    else
      (access_denied and return) unless current_user&.is_archivist?
    end
  end

  def do_redirect
    url = params[:original_url]
    if url.blank?
      flash[:error] = t(".no_url")
    else
      @work = Work.find_by_url(url)
      if @work
        flash[:notice] = t(".redirected_from", original_url: url)
        redirect_to(work_path(@work)) and return
      else
        flash[:error] = t(".no_work_found")
      end
    end
    redirect_to(redirect_path) and return
  end

  def show
    redirect_to(action: :do_redirect, original_url: params[:original_url])
  end
end
