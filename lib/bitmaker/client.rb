require 'uri'
require 'net/http'
require 'multi_json'
require 'jwt'

module Bitmaker
  class Client
    class MissingClientCredentialsError < RuntimeError; end
    class AccessTokenDeniedError < RuntimeError; end
    class HttpResponseError < RuntimeError
      attr_reader :response

      def initialize(message, response)
        @message = message
        @response = response
      end
    end

    AUTH_URL = URI('https://bitmaker.auth0.com/oauth/token')
    DEFAULT_BASE_URI = 'https://api.bitmaker.co'
    DEFAULT_TIMEOUT = 10
    HEADERS = {
      "Accept" => 'application/vnd.api+json',
      "User-Agent" => "Bitmaker/v1 Ruby/#{VERSION}"
    }

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

      # TODO: Only fetch new token when expired (maybe?)
      @access_token = fetch_access_token["access_token"]
    end

    def create(resource_name, payload)
      resource_class = "Bitmaker::#{resource_name.to_s.classify}".constantize
      resource = resource_class.new(payload)

      # send the request
      response = request(:post, resource.create_path, payload)

      resource
    end

    protected
    def fetch_access_token
      http = Net::HTTP.new(AUTH_URL.host, AUTH_URL.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Post.new(AUTH_URL)
      request["content-type"] = 'application/json'
      request.body = MultiJson.dump({
                                      grant_type: 'client_credentials',
                                      client_id: @client_id,
                                      client_secret: @client_secret,
                                      audience: DEFAULT_BASE_URI
                                    })

      response = http.request(request)
      payload = MultiJson.load(response.read_body)

      if (response.code.to_i >= 200 && response.code.to_i <= 300) && payload["error"].nil?
        payload
      else
        raise AccessTokenDeniedError.new(payload["error_description"])
      end
    end

    def request(method, path, body = nil)
      uri = URI.join(DEFAULT_BASE_URI, path)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = DEFAULT_TIMEOUT
      http.read_timeout = DEFAULT_TIMEOUT

      request = request_class(method).new(uri.path)
      request.initialize_http_header(HEADERS)

      # Set Content-Type when there's a body
      unless body.nil?
        request.add_field('Content-Type', 'application/vnd.api+json')
        request.body = MultiJson.dump(body)
      end

      response = http.request(request)

      if response.code.to_i >= 200 && response.code.to_i < 300
        response
      else
        raise HttpResponseError.new("Bitmaker API returned an error response: #{response.code}", response)
      end
    end

    def request_class(method)
      case method
      when :post
        Net::HTTP::Post
      when :patch
        Net::HTTP::Patch
      when :put
        Net::HTTP::Put
      when :delete
        Net::HTTP::Delete
      else
        raise InvalidRequest.new("Invalid request method #{method.inspect}")
      end
    end
  end
end
