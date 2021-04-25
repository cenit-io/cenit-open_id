require "cenit/open_id/version"

module Cenit
  module OpenId
    include BuildInApps

    config =
      begin
        YAML.load(File.read("#{__dir__}/open_id/config.yaml"))
      rescue
        {}
      end

    config[:providers] = config.keys

    CONFIG = JSON.parse(config.to_json, object_class: OpenStruct)

    default_redirect_uris << -> { "#{Cenit.homepage}/users/sign_in" }

    module_function

    def providers?
      !providers.empty?
    end

    def providers
      app = self.app
      providers = CONFIG.providers.map do |provider|
        [app.configuration_attributes["#{provider}_client_id"], provider]
      end.to_h
      app.tenant.switch do
        Setup::OauthClient.where(:id.in => providers.keys).map do |client|
          providers[client.id]
        end
      end
    end

    def get_user_by(code)
      app.tenant.switch do
        (code = Code.where(value: code).first) &&
          code.active? &&
          User.where(id: code.metadata['user_id']).first
      end
    end
  end
end

require 'cenit/open_id/code'
require 'cenit/open_id/user'
require 'cenit/open_id/controller'
require 'cenit/open_id/setup'
