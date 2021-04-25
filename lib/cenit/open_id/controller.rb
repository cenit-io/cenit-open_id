module Cenit
  module OpenId

    controller do

      get '/' do
        profile_uri = "/app/#{app.key}/profile"
        errors = []
        errors << 'Invalid response_type.' unless params[:response_type].nil? || params[:response_type] == 'code'
        if (redirect_uri = params[:redirect_uri] || profile_uri)
          errors << 'Invalid redirect_uri.' unless redirect_uri == profile_uri || redirect_uris.include?(redirect_uri)
        else
          redirect_uri == 'profile'
        end
        if (provider = params[:with])
          errors << "Provider #{provider} not supported." unless (client = configuration["#{provider}_client"])
        end
        if errors.blank?
          if provider
            auth = client.create_authorization!(
              namespace: 'OpenID',
              scopes: OpenId::CONFIG[provider].scope || configuration["#{provider}_scope"],
              metadata: {
                provider: provider,
                redirect_uri: redirect_uri,
                state: params[:state]
              })
            authorize(auth)
          else
            render :index, locals: {
              app: app,
              client_id: app.identifier,
              logo: logo,
              providers: CONFIG.providers,
              redirect_uri: redirect_uri
            }
          end
        else
          render json: { errors: errors }, status: :bad_request
        end
      end

      get '/authorization/:id' do
        errors = []
        status = :not_acceptable
        if (auth = Setup::Authorization.where(id: params[:id]).first)
          if auth.metadata['redirect_token'] == params[:redirect_token]
            if (provider = auth.metadata['provider']) && (redirect_uri = auth.metadata['redirect_uri'])
              if auth.authorized?
                get_profile_method = :"get_#{provider}_profile"
                profile = nil
                if respond_to?(get_profile_method)
                  profile = send(get_profile_method, auth)
                end
                if auth.id_token
                  profile = profile.merge(profile_from_id_token(auth.id_token)) { |_, a, b| b || a }
                end
                if profile
                  if profile[:email].present?
                    user = User.create_from_json(profile, primary_field: :email)
                    if user.errors.blank?
                      code = Code.create_from_json(metadata: { user_id: user.id.to_s })
                      redirect_uri += '?code=' + code.value
                      if (state = auth.metadata['state'])
                        redirect_uri += '&state=' + URI.encode(state)
                      end
                      redirect_to redirect_uri
                    else
                      errors << "Bad user profile: #{user.errors.full_messages.to_sentence}"
                    end
                  else
                    errors << "It seems that your #{provider} account is not confirmed so it can not be used for authentication"
                  end
                else
                  errors << "Unable to retrieve user profile, either provider '#{provider}' is not supported or the authorization ID Token is missing, inspect your notifications for details"
                end
              else
                redirect_to redirect_uri + '?error=' + URI.encode('Not authorized')
              end
            else
              errors << 'Invalid authorization state'
            end
            auth.destroy
          else
            errors << "Invalid access"
          end
        else
          errors << "Authorization with ID #{params[:id]} not found"
          status = :not_found
        end

        if errors.present?
          render json: { errors: errors }, status: status
        end
      end

      get '/profile' do
        if (code = Code.where(value: params[:code]).first) && code.active? &&
          (user = User.where(id: code.metadata['user_id']).first)
          code.destroy
          render :profile, locals: {
            user: user,
            app: app
          }
        else
          render json: {
            error: 'Invalid code'
          }, status: :bad_request
        end
      end

      def profile_from_id_token(id_token)
        payload = JWT.decode(id_token, nil, false, verify_expiration: false)[0]
        {
          email: payload['email'],
          name: payload['name'],
          given_name: payload['given_name'],
          family_name: payload['family_name'],
          middle_name: payload['middle_name'],
          picture_url: payload['picture']
        }
      end

      def get_google_profile(authorization)
        profile = Setup::Connection.get(
          CONFIG.google.profile_url
        ).with(authorization).submit do |response|
          begin
            JSON.parse(response.body)
          rescue
            {}
          end
        end
        profile.delete('id')
        profile[:picture_url] = profile.delete('picture')
        profile.symbolize_keys
      end

      def get_facebook_profile(authorization)
        profile = Setup::Connection.get(
          CONFIG.facebook.profile_url
        ).with(authorization).submit do |response|
          begin
            JSON.parse(response.body)
          rescue
            {}
          end
        end
        {
          email: profile['email'],
          first_name: profile['firstname'],
          family_name: profile['lastname'],
          picture_url: (p = profile['picture']) && (p = p['data']) && p['url']
        }
      end

      def get_github_profile(authorization)
        profile = Setup::Connection.get(
          CONFIG.github.profile_url
        ).with(authorization).submit do |response|
          begin
            JSON.parse(response.body)
          rescue
            {}
          end
        end
        profile = {
          name: profile['name'],
          picture_url: profile['avatar_url']
        }
        emails = Setup::Connection.get(
          CONFIG.github.emails_url
        ).with(authorization).submit do |response|
          begin
            JSON.parse(response.body)
          rescue
            {}
          end
        end
        puts JSON.pretty_generate(emails)
        profile[:email] = emails.detect { |data| data['verified'] }['email']
        profile
      end
    end
  end
end