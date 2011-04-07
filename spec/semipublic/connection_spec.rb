require 'spec_helper'

describe 'A Connection instance' do

  URI_FRAGMENTS = DataMapperRest::Spec::URI_FRAGMENTS

  let(:uri) { Addressable::URI.new(
    :scheme   => URI_FRAGMENTS[:protocol],
    :user     => URI_FRAGMENTS[:username],
    :password => URI_FRAGMENTS[:password],
    :host     => URI_FRAGMENTS[:host],
    :port     => URI_FRAGMENTS[:port]
  ) }

  let(:connection) { DataMapperRest::Connection.new(uri, :__unused__) }

  it "should construct a valid uri" do
    connection.uri.to_s.should eql(DataMapperRest::Spec::URI)

    connection.uri.host.should     eql(URI_FRAGMENTS[:host])
    connection.uri.port.should     eql(URI_FRAGMENTS[:port])
    connection.uri.user.should     eql(URI_FRAGMENTS[:username])
    connection.uri.password.should eql(URI_FRAGMENTS[:password])
  end

  it "should return the correct extension and mime type for xml" do
    connection.format.headers.should eql(
      'Accept'       => 'application/xml',
      'Content-Type' => "application/xml"
    )
  end

  it "should return the correct extension and mime type for json" do
    pending("Awaiting the JSON format") do
      connection = DataMapperRest::Connection.new(uri, "json")
      connection.format.headers.should eql(
        'Accept'       => 'application/json',
        'Content-Type' => "application/json"
      )
    end
  end

  describe 'when running the action methods' do

    let(:full_uri) do
      uri.dup.tap { |u| u.path = 'foobars.xml' }
    end

    let(:headers) do
      { 'Content-Type' => 'application/xml',
        'Accept'       => 'application/xml' }
    end

    it 'should make an HTTP Post' do
      post('foobars.xml')
      connection.http_post("foobars", "<somexml>")

      WebMock.should have_requested(:post, full_uri).with(
        :body => '<somexml>', :headers => headers)
    end

    it 'should make an HTTP Head' do
      head('foobars.xml')
      connection.http_head("foobars")

      WebMock.should have_requested(:head, full_uri).with(
        :body => nil, :headers => headers)
    end

    it 'should make an HTTP Get' do
      get('foobars.xml')
      connection.http_get("foobars")

      WebMock.should have_requested(:get, full_uri).with(
        :body => nil, :headers => headers)
    end

    it 'should make an HTTP Put' do
      put('foobars.xml')
      connection.http_put("foobars", "<somexml>")

      WebMock.should have_requested(:put, full_uri).with(
        :body => '<somexml>', :headers => headers)
    end

    it 'should make an HTTP Delete' do
      delete('foobars.xml')
      connection.http_delete("foobars", "<somexml>")

      WebMock.should have_requested(:delete, full_uri).with(
        :body => '<somexml>', :headers => headers)
    end

    it 'should preserve params' do
      get('foobars.xml?lolcode')
      connection.http_get("foobars?lolcode")

      expected = uri.dup.tap { |u| u.path = 'foobars.xml?lolcode' }
      WebMock.should have_requested(:get, expected.to_s)
    end

  end

  describe "when receiving error response codes" do

    it 'should return the response on 200' do
      post('test.xml', 200)
      connection.http_post('test').should be_a(Net::HTTPOK)
    end

    it 'should return the response on 201' do
      post('test.xml', 200)
      connection.http_post('test').should be_a(Net::HTTPOK)
    end

    it "should redirect on 301" do
      post('test.xml', 301)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::Redirection)
    end

    it "should redirect on 302" do
      post('test.xml', 302)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::Redirection)
    end

    it "should raise bad request on 400" do
      post('test.xml', 400)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::BadRequest)
    end

    it "should raise UnauthorizedAccess on 401" do
      post('test.xml', 401)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::UnauthorizedAccess)
    end

    it "should raise ForbiddenAccess on 401" do
      post('test.xml', 403)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::ForbiddenAccess)
    end

    it "should raise 404" do
      post('test.xml', 404)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::ResourceNotFound)
    end

    it "should raise MethodNotAllowed on 405" do
      post('test.xml', 405)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::MethodNotAllowed)
    end

    it "should raise ResourceConflict on 409" do
      post('test.xml', 409)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::ResourceConflict)
    end

    it "should raise ResourceInvalid on 422" do
      post('test.xml', 422)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::ResourceInvalid)
    end

    it "should raise ServerError on 500" do
      post('test.xml', 500)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::ServerError)
    end

    it "should raise ConnectionError on other codes" do
      post('test.xml', 900)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::ConnectionError)
    end

  end
end
