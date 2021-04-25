module Cenit
  module OpenId

    setup do
      begin
        app = self.app
        app.configuration.logo = ActionController::Base.helpers.asset_path('open_id/logo.png')
        app.save
      rescue Exception => ex
        puts "ERROR configuring OpenID app logo: #{ex.message}"
      end
    end
  end
end