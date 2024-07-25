
# Dispatcher.to_prepare do
#   AccountController.send(:include, AccountControllerPatch) unless AccountController.included_modules.include? AccountControllerPatch
# end

require_relative 'lib/redmine_proxyauth/account_controller_patch'

Redmine::Plugin.register :redmine_proxyauth do
  name 'Redmine Proxyauth plugin'
  author 'Alexander Vowinkel'
  description 'Log in users via HTTP headers set by oauth2-proxy'
  version '0.0.1'
  url 'https://github.com/FES-Ehemalige/redmine_proxyauth'
  author_url 'https://github.com/kaktus42'

  requires_redmine version_or_higher: '5.1.0'

  settings default: {
    client_id: '',
    client_secret: '',
    tenant_id: '',
  }, partial: 'settings/proxyauth_settings'
end
