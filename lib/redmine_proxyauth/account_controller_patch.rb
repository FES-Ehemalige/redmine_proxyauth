module RedmineProxyauth
  module AccountControllerPatch

    def login
      id_token = get_id_token
      if !id_token
        flash[:error] = l(:proxyauth_missing_token)
        super
        return
      end

      if User.current.logged?
        redirect_back_or_default home_url, :referer => true
      end

      email, given_name, family_name = "", "", ""

      if request.headers['X-Auth-Request-Access-Token'].present?
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

        Rails.logger.info user.registered?
        Rails.logger.info user.active?

        if user.registered? # Registered
          account_pending user
        elsif user.active? # Active
          handle_active_user user
          user.update_last_login_on!
        else # Locked
          handle_inactive_user user
        end

      end
    end

    def logout
      if User.current.anonymous?
        redirect_to home_url
      elsif request.post?
        id_token = get_id_token

        redirect_url = "/oauth2/sign_out"
        redirect_url += "?rd=" + CGI.escape(
          "#{Setting.plugin_redmine_proxyauth[:tenant_uri]}/realms/#{Setting.plugin_redmine_proxyauth[:tenant_id]}/protocol/openid-connect/logout"
        )

        if !id_token
          Rails.logger.error "Could not connect to IDP - Full logout not possible."
        else
          redirect_url += CGI.escape("?id_token_hint=#{id_token}&post_logout_redirect_uri=#{home_url}")
        end

        logout_user
        redirect_to redirect_url
      end
    end

    def get_id_token
      begin
        resp = Net::HTTP.post_form(
          URI("#{Setting.plugin_redmine_proxyauth[:tenant_uri]}/realms/#{Setting.plugin_redmine_proxyauth[:tenant_id]}/protocol/openid-connect/token"),
          {
            "client_id" => Setting.plugin_redmine_proxyauth[:client_id],
            "client_secret" => Setting.plugin_redmine_proxyauth[:client_secret],
            "grant_type" => "client_credentials",
            "scope" => "openid"
          }
        )
        body = JSON.parse(resp.body)
        id_token = body["id_token"]
      rescue SocketError => e
        Rails.logger.warn "Could not connect to IDP: #{e}"
      end
      id_token
    end

  end
end

unless AccountController.included_modules.include?(RedmineProxyauth::AccountControllerPatch)
  AccountController.prepend(RedmineProxyauth::AccountControllerPatch)
end
