# frozen_string_literal: true

require_relative '../config'

# Various utilities
module Utils
  def self.valid_login?(user, pass)
    user = Unix.user(user) if Unix.user?(user)
    pass = pass.to_s
    return false unless user.is_a?(Unix::User)

    user.compare_password(pass)
  end
end
