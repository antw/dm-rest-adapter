share_examples_for 'a GET-like request' do
  # Expects a  let(:method) to be defined which returns a symbol indicating
  # the HTTP method to be tested (e.g., :get, :head).

  let(:connection_method) { :"http_#{method}" }
  let(:connection)        { DataMapperRest::Connection.new(base_uri, :__unused__) }

  let(:headers) do
    { 'Content-Type' => 'application/xml',
      'Accept'       => 'application/xml' }
  end

  # --------------------------------------------------------------------------

  context 'when the adapter URI has no params' do
    let(:base_uri) { Addressable::URI.parse(DataMapperRest::Spec::URI) }

    it 'should send a correctly-formed request' do
      register_uri_with_body(method, 'foobars')
      connection.__send__(connection_method, 'foobars')

      expected = base_uri.dup.tap { |u| u.path = 'foobars' }
      WebMock.should have_requested(method.to_sym, expected).with(
        :body => nil, :headers => headers)
    end

    it 'should preserve params from the the request' do
      register_uri_with_body(method, 'foobars?widget=yes')
      connection.__send__(connection_method, 'foobars', :widget => 'yes')

      expected = base_uri.dup.tap { |u| u.path = 'foobars?widget=yes' }
      WebMock.should have_requested(method.to_sym, expected.to_s)
    end

    it 'should raise an error if trying to send data' do
      expect {
        connection.__send__(:"http_#{method}", 'foobars', '<data>')
      }.to raise_error("Cannot send request body with " \
                       "a #{Regexp.escape(method.upcase)} request")
    end
  end # when the adapter URI has no params

  # --------------------------------------------------------------------------

  context 'when the connection is told to use the format extension' do
    let(:connection) { DataMapperRest::Connection.new(base_uri, :__unused__, true) }
    let(:base_uri)   { Addressable::URI.parse(DataMapperRest::Spec::URI) }

    it 'should append the format extension' do
      register_uri_with_body(method, 'foobars.xml')
      connection.__send__(connection_method, 'foobars')

      expected = base_uri.dup.tap { |u| u.path = 'foobars.xml' }
      WebMock.should have_requested(method.to_sym, expected)
    end

    it 'should preserve params from the the request' do
      register_uri_with_body(method, 'foobars.xml?widget=yes')
      connection.__send__(connection_method, 'foobars', :widget => 'yes')

      expected = base_uri.dup.tap { |u| u.path = 'foobars.xml?widget=yes' }
      WebMock.should have_requested(method.to_sym, expected.to_s)
    end
  end # when the connection is told to use the format extension

  # --------------------------------------------------------------------------

  context 'when the adapter URI has params' do
    let(:base_uri) {
      Addressable::URI.parse("#{DataMapperRest::Spec::URI}?baz=no")
    }

    it 'should preserve params when sending the request' do
      register_uri_with_body(method, 'foobars?baz=no')
      connection.__send__(connection_method, 'foobars')

      expected = base_uri.dup.tap do |uri|
        uri.path  = 'foobars'
        uri.query = 'baz=no'
      end

      WebMock.should have_requested(method.to_sym, expected).with(
        :body => nil, :headers => headers)
    end

    it 'should merge params with those given' do
      register_uri_with_body(method, 'foobars?baz=no&widget=yes')
      connection.__send__(connection_method, 'foobars', :widget => 'yes')

      expected = base_uri.dup.tap do |uri|
        uri.path  = 'foobars'
        uri.query = 'baz=no&widget=yes'
      end

      WebMock.should have_requested(method.to_sym, expected)
    end
  end
end # a GET-like request
