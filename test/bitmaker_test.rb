require 'test_helper'
require 'active_support/time'

describe Bitmaker do
  let (:client_id) { 'CLIENT_ID' }
  let (:client_secret) { 'CLIENT_SECRET' }
  let(:body) { { grant_type: 'client_credentials',
                  client_id: client_id,
                  client_secret: client_secret,
                  audience: Bitmaker::Client::DEFAULT_BASE_URI } }
  let(:expiry) { Time.now.utc + 1.day }

  def json(data)
    MultiJson.dump(data)
  end

  def generate_access_token(expiry:)
    rsa_private = OpenSSL::PKey::RSA.generate 2048
    token = JWT.encode({"exp": expiry.to_i}, rsa_private, 'RS256')

    @public_key = rsa_private.public_key
    @access_token = { access_token: token, expires_in: expiry.to_i - Time.now.utc.to_i, token_type: 'Bearer' }
  end

  describe 'Client' do
    before do
      generate_access_token(expiry: expiry)
    end

    it 'raises an exception when no credentials provided' do
      Bitmaker::Client.client_id = nil
      Bitmaker::Client.client_secret = nil

      -> { Bitmaker::Client.new }.must_raise Bitmaker::Client::MissingClientCredentialsError
    end

    describe '#create' do
      let(:activity_params) {
        {
          inquiry_type: 'general',
          first_name: 'Fred',
          last_name: 'Flintstone',
          email: 'fred@flintstone.com'
        }
      }

      before do
        stub_request(:post, Bitmaker::Client::AUTH_URL.to_s)
          .with(
            body: json(body),
            headers: { 'content-type' => 'application/json' })
          .to_return(status: 200, body: json(@access_token) )

        @stub_create = stub_request(:post, Bitmaker::Client::DEFAULT_BASE_URI + '/v1/activities/inquiries')
                        .to_return(status: 201)

        Bitmaker::Client.client_id = client_id
        Bitmaker::Client.client_secret = client_secret

        @client = Bitmaker::Client.new
      end

      describe 'getting access token' do
        describe 'when credentials set on instance' do
          it "fetches an access token on initialization" do
            client = Bitmaker::Client.new(client_id: client_id, client_secret: client_secret)

            client.create(:inquiries, activity_params)

            client.access_token.must_equal @access_token[:access_token]
          end
        end

        describe 'when credentials set on class' do
          before do
            @client.create(:inquiries, activity_params)
          end

          it "fetches an access token on initialization" do
            @client.access_token.must_equal @access_token[:access_token]
          end

          it 'sets the access token expiry' do
            @client.access_token_expiry.wont_be_nil
          end

          it 'sets the access token expiry to match the access token payload' do
            @client.access_token_expiry.must_be_within_delta expiry, 1.second
          end
        end
      end

      it "should send a POST request to API with good params" do
        @client.create(:inquiries, activity_params)
        assert_requested @stub_create
      end

      it "should set the Authorization header on each request" do
        @client.create(:inquiries, activity_params)
        assert_requested(:post, Bitmaker::Client::DEFAULT_BASE_URI + '/v1/activities/inquiries', times: 1) do |req|
          req.headers.must_include 'Authorization'
          req.headers['Authorization'].must_equal "Bearer #{@access_token[:access_token]}"
        end
      end

      it "should set the json-api header on each request" do
        @client.create(:inquiries, activity_params)
        assert_requested(:post, Bitmaker::Client::DEFAULT_BASE_URI + '/v1/activities/inquiries', times: 1) do |req|
          req.headers.must_include 'Content-Type'
          req.headers['Content-Type'].must_equal 'application/vnd.api+json'
        end
      end

      it "should set the body to a json-api serialized Inquiry" do
        @client.create(:inquiries, activity_params)
        assert_requested(:post, Bitmaker::Client::DEFAULT_BASE_URI + '/v1/activities/inquiries', times: 1) do |req|
          req.body.must_equal json(Bitmaker::Inquiry.new(activity_params).serialize)
        end
      end

      it "should return a Inquiry given good params" do
        @client.create(:inquiries, activity_params).must_be_instance_of Bitmaker::Inquiry
      end

      it "should return a well-formed Inquiry" do
        inquiry = @client.create(:inquiries, activity_params)
        inquiry.inquiry_type.must_equal "general"
        inquiry.lead.must_be_instance_of Bitmaker::Lead
        inquiry.lead.first_name.must_equal 'Fred'
        inquiry.lead.last_name.must_equal 'Flintstone'
      end

      it "should raise a NameError on a bad resource name" do
        -> { @client.create(:fake_resource, activity_params) }.must_raise NameError
      end

      describe 'when access token is close to expiry' do
        before do
          @expiry = Time.now.utc + 15.minutes

          generate_access_token(expiry: @expiry)

          stub_request(:post, Bitmaker::Client::AUTH_URL.to_s)
            .with(
              body: json(body),
              headers: { 'content-type' => 'application/json' })
            .to_return(status: 200, body: json(@access_token) )

          @client = Bitmaker::Client.new
        end

        it 'should fetch a new access token' do
          @client.expects(:set_access_token)
          @client.create(:inquiries, activity_params)
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

              Bitmaker::Client.client_id = client_id
              Bitmaker::Client.client_secret = client_secret

              @client = Bitmaker::Client.new
          end

          it "raises an exception with error message" do
            error = -> { @client.create(:inquiries, activity_params) }.must_raise Bitmaker::Client::AccessTokenDeniedError
            error.message.wont_be_nil
          end
        end
      end
    end
  end

  describe 'Inquiry' do
    let(:activity) {
      Bitmaker::Inquiry.new(inquiry_type: 'general',
                            first_name: 'Fred',
                            last_name: 'Flintstone',
                            email: 'fred@flintstone.com')
    }

    it "whitelists attributes" do
      activity = Bitmaker::Inquiry.new(inquiry_type: 'general', random_attribute: 'blacklisted')
      activity.inquiry_type.must_equal 'general'
      activity.random_attribute.must_be_nil
    end

    it "sets the lead accessor to a valid Lead" do
      activity.lead.wont_be_nil
      activity.lead.must_be_instance_of Bitmaker::Lead
      activity.lead.first_name.must_equal "Fred"
      activity.lead.last_name.must_equal "Flintstone"
      activity.lead.email.must_equal "fred@flintstone.com"
    end

    it "should serialize to a Hash" do
      serialized = activity.serialize(included_models: ['lead'])
      serialized.must_be_instance_of Hash
    end

    it "should serialize in json-api format" do
      serialized = activity.serialize(included_models: ['lead'])
      serialized.dig('data').must_be_instance_of Hash
      serialized.dig('data', 'attributes', 'inquiry_type').must_equal 'general'
      serialized.dig('data', 'relationships', 'lead', 'data', 'type').must_equal 'leads'
      serialized.dig('included').must_be_instance_of Array
      serialized.dig('included').first.dig('type').must_equal 'leads'
      serialized.dig('included').first.dig('attributes', 'email').must_equal 'fred@flintstone.com'
    end

    it "should return the correct create_path" do
      activity.create_path.must_equal '/v1/activities/inquiries'
    end
  end
end
