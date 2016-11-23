require 'test_helper'
require 'active_support/time'

describe Bitmaker do
  let (:client_id) { 'CLIENT_ID' }
  let (:client_secret) { 'CLIENT_SECRET' }
  let(:body) { { grant_type: 'client_credentials',
                  client_id: 'CLIENT_ID',
                  client_secret: 'CLIENT_SECRET',
                  audience: Bitmaker::Client::IDENTIFIER } }

  def json(data)
    MultiJson.dump(data)
  end

  def generate_access_token
    rsa_private = OpenSSL::PKey::RSA.generate 2048
    token = JWT.encode({"exp": (Time.now.utc + 1.day).to_i}, rsa_private, 'RS256')

    @public_key = rsa_private.public_key
    @access_token = { access_token: token, token_type: 'Bearer' }
  end

  it 'raises an exception when no credentials provided' do
    Bitmaker::Client.client_id = nil
    Bitmaker::Client.client_secret = nil

    -> { Bitmaker::Client.new }.must_raise Bitmaker::Client::MissingClientCredentialsError
  end

  describe 'getting access token' do
    before do
      # A time between the issued and expiry for the access_token
      Timecop.freeze(Time.at(1479957567))

      generate_access_token

      stub_request(:post, Bitmaker::Client::AUTH_URL.to_s)
        .with(
          body: json(body),
          headers: { 'content-type' => 'application/json' })
        .to_return(status: 200, body: json(@access_token) )
    end

    after do
      Timecop.return
    end

    describe 'when credentials set on instance' do
      it "fetches an access token on initialization" do
        client = Bitmaker::Client.new(client_id: "CLIENT_ID", client_secret: "CLIENT_SECRET")
        client.access_token.must_equal @access_token[:access_token]
      end
    end

    describe 'when credentials set on class' do
      before do
        Bitmaker::Client.client_id = "CLIENT_ID"
        Bitmaker::Client.client_secret = "CLIENT_SECRET"
      end

      it "fetches an access token on initialization" do
        client = Bitmaker::Client.new
        client.access_token.must_equal @access_token[:access_token]
      end
    end
  end

  describe 'getting error from Auth0' do
    let(:error) { { error: "access_denied",
                    error_description: "Client is not authorized to access \"https://api.bitmaker.co\". You might probably want to create a \"client-grant\" associated to this API. See: https://auth0.com/docs/api/v2#!/Client_Grants/post_client_grants"} }
    before do
      stub_request(:post, Bitmaker::Client::AUTH_URL.to_s)
        .with(
          body: json(body),
          headers: { 'content-type' => 'application/json' })
        .to_return(status: 503, body: json(error) )

        Bitmaker::Client.client_id = "CLIENT_ID"
        Bitmaker::Client.client_secret = "CLIENT_SECRET"
    end

    it "raises an exception with error message" do
      error = -> { Bitmaker::Client.new }.must_raise Bitmaker::Client::AccessTokenDeniedError
      error.message.wont_be_nil
    end
  end
end
