module DataMapperRest
  module Spec
    module WebmockHelpers

      URI = "http://admin:secret@localhost:4000"

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
            DataMapper.repository(:memory) { yield }
          else '' end

        stub_request(method, "#{URI}/#{path}").to_return(
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

    end # WebmockHelpers
  end # Spec
end # DataMapperRest
