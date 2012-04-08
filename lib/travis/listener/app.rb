require 'sinatra'
require 'travis/support/logging'
require 'newrelic_rpm'

module Travis
  module Listener
    class App < Sinatra::Base
      include Logging

      # use Rack::CommonLogger for request logging
      enable :logging, :dump_errors

      # Used for new relic uptime monitoring
      get '/uptime' do
        200
      end

      # the main endpoint for scm services
      post '/' do
        # info "## Handling ping ##"

        data = {
          :credentials => credentials,
          :request => payload
        }

        requests.publish(data, :type => 'request')

        # info "## Request created : #{params[:payload].inspect} ##"

        204
      end

      protected

      def requests
        @requests ||= Travis::Amqp::Publisher.builds('builds.requests')
      end

      def credentials
        login, token = Rack::Auth::Basic::Request.new(env).credentials
        { :login => login, :token => token }
      end

      def payload
        MultiJson.decode(params[:payload])
      end
    end
  end
end
