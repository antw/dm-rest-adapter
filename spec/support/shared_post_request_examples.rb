share_examples_for 'a POST-like request' do
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
      register_uri_with_body(method, 'foobars.xml')
      connection.__send__(connection_method, 'foobars')

      expected = base_uri.dup.tap { |u| u.path = 'foobars.xml' }
      WebMock.should have_requested(method.to_sym, expected).
        with(:body => nil, :headers => headers)
    end

    it 'should send the given request body' do
      register_uri_with_body(method, 'foobars.xml')
      connection.__send__(:"http_#{method}", 'foobars', '<data>')

      expected = base_uri.dup.tap { |u| u.path = 'foobars.xml' }
      WebMock.should have_requested(method.to_sym, expected).
        with(:body => '<data>')
    end

    it 'should preserve params from the the request' do
      expect {
        connection.__send__(connection_method, 'foobars', :widget => 'yes')
      }.to raise_error("Cannot send params with a #{method.upcase} request")
    end
  end # when the adapter URI has no params

  # --------------------------------------------------------------------------

  context 'when the adapter URI has params' do
    let(:base_uri) {
      Addressable::URI.parse("#{DataMapperRest::Spec::URI}?baz=no")
    }

    it 'should preserve params when sending the request' do
      register_uri_with_body(method, 'foobars.xml?baz=no')
      connection.__send__(connection_method, 'foobars')

      expected = base_uri.dup.tap do |uri|
        uri.path  = 'foobars.xml'
        uri.query = 'baz=no'
      end

      WebMock.should have_requested(method.to_sym, expected).with(
        :body => nil, :headers => headers)
    end

  end
end # a POST-like request
