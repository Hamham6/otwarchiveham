class RedirectPolicy < ApplicationPolicy
  REDIRECT_ACCESS_ROLES = %w[superadmin open_doors].freeze

  def index?
    user_has_roles?(REDIRECT_ACCESS_ROLES)
  end

  alias show? index?
end
