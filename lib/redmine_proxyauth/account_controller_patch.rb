module RedmineProxyauth
  module AccountControllerPatch

    def login
      if User.current.logged?
        redirect_back_or_default home_url, :referer => true
      end

      email, given_name, family_name = "", "", ""

      if !request.headers['X-Auth-Request-Access-Token'].present?
        flash[:error] = l(:proxyauth_missing_token)
        super
        return
      end

      token = request.headers['X-Auth-Request-Access-Token']
      decoded_token = JWT.decode token, nil, false
      given_name = decoded_token[0]["given_name"]
      family_name = decoded_token[0]["family_name"]
      email = decoded_token[0]["email"]

      Rails.logger.info "Found token for: #{email} / #{given_name} #{family_name}"

      user = User.find_by_mail(email)
      if user.nil?
        Rails.logger.error "User with email #{email} not found."
        flash[:error] = l(:proxyauth_user_not_found, email: email)
        return
      end

      if user.firstname != given_name || user.lastname != family_name
        Rails.logger.error "User with email #{email} has changed name from #{user.firstname} #{user.lastname} to #{given_name} #{family_name}. Not logging in."
        flash[:error] = l(:proxyauth_user_inconsistent)
        return
      end

      if user.registered? # Registered
        account_pending user
      elsif user.active? # Active
        handle_active_user user
        user.update_last_login_on!
      else # Locked
        handle_inactive_user user
      end
    end

    def logout
      if User.current.anonymous?
        redirect_to home_url
      elsif request.post?
        logout_user
        redirect_to "/oauth2/sign_out?rd=#{CGI.escape(home_url)}"
      end
    end

  end
end

unless AccountController.included_modules.include?(RedmineProxyauth::AccountControllerPatch)
  AccountController.prepend(RedmineProxyauth::AccountControllerPatch)
end
