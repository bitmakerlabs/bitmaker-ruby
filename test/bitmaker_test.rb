require 'test_helper'
require 'active_support/time'

describe Bitmaker do
  let (:client_id) { 'CLIENT_ID' }
  let (:client_secret) { 'CLIENT_SECRET' }

  before do
    rsa_private = OpenSSL::PKey::RSA.generate 2048
    token = JWT.encode({"exp": (Time.now.utc + 1.day).to_i}, rsa_private, 'RS256')

    @public_key = rsa_private.public_key
    @access_token = { access_token: token, token_type: 'Bearer' }
  end

  # Real access token generated via jwt.io
  # let (:access_token) { { access_token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IlJrUTRSREZETmtNMFFqRTRSVGhCTmpVMFFUbEZNREJHTjBGRU9UWkNSalZDUmtJMVJqUkJNdyJ9.eyJpc3MiOiJodHRwczovL2JpdG1ha2VyLmF1dGgwLmNvbS8iLCJzdWIiOiJGNThZcU50UXV6YXIzQ3dXVXpZVmJrWHBaV0Iyb3dQUkBjbGllbnRzIiwiYXVkIjoiaHR0cHM6Ly9hcGkuYml0bWFrZXIuY28iLCJleHAiOjE0Nzk5Mzc1NjcsImlhdCI6MTQ3OTg1MTE2Nywic2NvcGUiOiIifQ.Bg9iKeKZ2Re14ioC8T4phc_R-jWRALQKxdWVGTAjZ3FFlToxWqyzuKHU7ePNS6x5K-DwknyXsfyRrIDA4uImE74rHQYkmt4ydEhTWrQZSRNR_cF_zGWNi2Ccv8vKtKeBd0oVaQtugMxi3d8i317PnY27ERuoxaeS7o63retItQyJKcIYOL4kbn2j7Ji3H8Ng3BiIlU9WsfzT5zTZTTqzmte0cTXt-oM4ZgoksCnkSEFux5h4w_XoJIlLTF-NLq2NR9sIfVq7mHU9g3SsYhGoRKFik1rUxsaz25eFm6jzOmhnGYGxbIBiV_pct40RxWXHfHyBYVxqw1NDWrSdhb_1iQ", token_type: "Bearer" } }

  def json(data)
    MultiJson.dump(data)
  end

  describe 'getting access token' do
    let(:body) { { grant_type: 'client_credentials',
                    client_id: 'CLIENT_ID',
                    client_secret: 'CLIENT_SECRET',
                    audience: Bitmaker::Client::IDENTIFIER } }

    before do
      # A time between the issued and expiry for the access_token
      Timecop.freeze(Time.at(1479957567))

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
end
