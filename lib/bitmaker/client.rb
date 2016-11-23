require 'uri'
require 'net/http'
require 'multi_json'
require 'jwt'

# TODO raise MissingClientCredentialsError if missing client_id and client_secret

module Bitmaker
  class Client
    class MissingClientCredentialsError < RuntimeError; end
    class AccessTokenDeniedError < RuntimeError; end

    IDENTIFIER = 'https://api.bitmaker.co'
    HOST = 'api.bitmaker.co'
    PORT = 443
    SSL = true
    HEADERS = { :accept => 'application/json' }
    AUTH_URL = URI('https://bitmaker.auth0.com/oauth/token')

    attr_reader :access_token

    class << self
      attr_accessor :client_id, :client_secret

      def method_missing(sym, *args, &block)
        new(client_id: self.client_id, client_secret: self.client_secret)
      end
    end

    def initialize(client_id: nil, client_secret: nil)
      @client_id = client_id || self.class.client_id || ENV['AUTH0_CLIENT_ID']
      @client_secret = client_secret || self.class.client_secret || ENV['AUTH0_CLIENT_SECRET']

      raise MissingClientCredentialsError.new('You must provide a valid client_id and client_secret') if @client_id.nil? && @client_secret.nil?

      ensure_valid_access_token
    end

    protected
    def set_access_token
      @access_token = fetch_access_token["access_token"]
    end

    def ensure_valid_access_token
      set_access_token if !access_token

      @access_token
    end

    def fetch_access_token
      http = Net::HTTP.new(AUTH_URL.host, AUTH_URL.port)
      http.use_ssl = SSL
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new(AUTH_URL)
      request["content-type"] = 'application/json'
      request.body = MultiJson.dump({
                                      grant_type: 'client_credentials',
                                      client_id: @client_id,
                                      client_secret: @client_secret,
                                      audience: IDENTIFIER
                                    })

      response = http.request(request)
      payload = MultiJson.load(response.read_body)

      if (response.code.to_i >= 200 && response.code.to_i <= 300) && payload["error"].nil?
        payload
      else
        raise AccessTokenDeniedError.new(payload["error_description"])
      end
    end

    def handle_error(error)
      set_access_token if error.is_a?(JWT::ExpiredSignature)
    end
  end
end
