module DataMapperRest
  module Spec

    URI_FRAGMENTS = {
      :protocol => 'http',
      :username => 'admin',
      :password => 'secret',
      :host     => 'localhost',
      :port     =>  4000
    }

    # Protocol, host, and port of test requests.
    URI = "%s://%s:%s@%s:%d" % [
      URI_FRAGMENTS[:protocol],
      URI_FRAGMENTS[:username], URI_FRAGMENTS[:password],
      URI_FRAGMENTS[:host],     URI_FRAGMENTS[:port]
    ]

    module WebmockHelpers

      # Registers a URI path with FakeWeb.
      #
      # register_uri_with_body yields a block which is run inside the memory
      # repository. The value returned by the block is used as the response
      # body.
      #
      # @param [Symbol] method
      #   The HTTP method to be registered. One of :get, :post, :put, :delete,
      #   :head, or :options.
      # @param [String] path
      #   The URI path, sans protocol, user, password, host, etc.
      # @param [Integer] status
      #   The response status.
      #
      # @return [WebMock::RequestStub]
      #
      # @example Register a URI which returns two books.
      #
      #   register_uri_with_body(:get, 'books.xml') do
      #     2.times { Book.gen }
      #     Book.all.to_json
      #   end
      #
      # @example Register a URI which returns a 404
      #
      #   register_uri_with_body(:get, 'books/1.xml', 404)
      #
      # @example Setting further expectations
      #
      #   register_uri_with_body(:get, 'books.lol').with(
      #     :body    => 'HAI ; KTHXBYE'
      #     :headers => { 'Content-Type' => 'application/lolcode' }
      #   )
      #
      def register_uri_with_body(method, path, status = 200)
        body =
          if block_given?
            returned = DataMapper.repository(:memory) { yield }

            # If this example is being executed within a with_formats block,
            # run the serializer on whatever the block returned.
            unless current_format.nil? or returned.kind_of?(String)
              returned = serialize_object(returned)
            end

            returned
          else '' end

        stub_request(method.to_sym, "#{URI}/#{path}").to_return(
          :body    => body,
          :status  => status,
          :headers => { 'Content-Length' => body.length })
      end

      # Wrappers around +register_uri_with_body+, for shorter examples.
      #
      # @see register_uri_with_body
      #
      %w( get post put delete options head ).each do |method|
        module_eval <<-RUBY
          def #{method}(path, status = 200, &block)
            register_uri_with_body(:#{method}, path, status, &block)
          end
        RUBY
      end

      # Returns a string URI, appending the given path to URI.
      #
      # @return [String]
      #
      def uri_for(path)
        "#{DataMapperRest::Spec::URI}/#{path}"
      end

    end # WebmockHelpers
  end # Spec
end # DataMapperRest
