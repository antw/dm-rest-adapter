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

  describe "when receiving error response codes" do

    it 'should return the response on 200' do
      post('test', 200)
      connection.http_post('test').should be_a(Net::HTTPOK)
    end

    it 'should return the response on 201' do
      post('test', 200)
      connection.http_post('test').should be_a(Net::HTTPOK)
    end

    it "should redirect on 301" do
      post('test', 301)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::Redirection)
    end

    it "should redirect on 302" do
      post('test', 302)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::Redirection)
    end

    it "should raise bad request on 400" do
      post('test', 400)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::BadRequest)
    end

    it "should raise UnauthorizedAccess on 401" do
      post('test', 401)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::UnauthorizedAccess)
    end

    it "should raise ForbiddenAccess on 401" do
      post('test', 403)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::ForbiddenAccess)
    end

    it "should raise 404" do
      post('test', 404)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::ResourceNotFound)
    end

    it "should raise MethodNotAllowed on 405" do
      post('test', 405)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::MethodNotAllowed)
    end

    it "should raise ResourceConflict on 409" do
      post('test', 409)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::ResourceConflict)
    end

    it "should raise ResourceInvalid on 422" do
      post('test', 422)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::ResourceInvalid)
    end

    it "should raise ServerError on 500" do
      post('test', 500)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::ServerError)
    end

    it "should raise ConnectionError on other codes" do
      post('test', 900)

      expect { connection.http_post('test') }.to \
        raise_error(DataMapperRest::ConnectionError)
    end

  end
end

describe DataMapperRest::Connection do

  context 'when configured not to use an extension' do
    let(:adapter) { DataMapper.setup(:test,
      :adapter   => 'rest',
      :format    => 'xml',
      :host      => 'localhost',
      :port      => 4000
    ) }

    it 'should not use an extension' do
      adapter.__send__(:connection).use_extension?.should_not be_true
    end
  end

  context 'when configured to use an extension' do
    let(:adapter) { DataMapper.setup(:test,
      :adapter   => 'rest',
      :format    => 'xml',
      :host      => 'localhost',
      :port      => 4000,
      :extension => true
    ) }

    it 'should use an extension' do
      adapter.__send__(:connection).use_extension?.should be_true
    end
  end

  %w( get head ).each do |method|
    context "when making a #{method.upcase} request" do
      let(:method) { method.to_sym }
      it_should_behave_like 'a GET-like request'
    end
  end

  %w( post put delete ).each do |method|
    context "when making a #{method.upcase} request" do
      let(:method) { method.to_sym }
      it_should_behave_like 'a POST-like request'
    end
  end

end
