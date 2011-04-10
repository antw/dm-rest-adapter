module DataMapperRest
  # Performs HTTP requests.
  #
  # @todo Support HTTPS.
  # @todo Handle nested resources, see prefix in ActiveResource.
  #
  class Connection

    # An empty hash used when merging query parameters with a URI.
    #
    # @see [Connection#uri_for_request]
    #
    EMPTY_HASH = Hash.new.freeze

    # The base URI for the repository.
    #
    # @return [Addressable::URI]
    #
    attr_accessor :uri

    # The Format instance used when sending and receiving requests.
    #
    # @return [Format::XML, Format::JSON, ...]
    #
    attr_accessor :format

    # Creates a new Connection instance (does not connect to the remote server
    # when initialized).
    #
    # @param [Addressable::URI] uri
    #   The URI supplied to DataMapper.setup(...) containing the base address
    #   for requests, port, protocol, etc.
    # @param [String] format
    #   The format to be used when making requests (currently not used).
    # @param [true, false] use_extension
    #   Indicates whether to append the format extension to URIs when making
    #   requests.
    #
    # @todo
    #   Use a registry to store formats so that users may define their own.
    #
    def initialize(uri, format, use_extension = false)
      @uri = uri
      @use_extension = use_extension

      @format = case format
        when 'xml'  then Formats::XML.new
        when 'json' then Formats::JSON.new
        else             raise "Unknown format: #{format}"
      end
    end

    # Create methods for easily sending HTTP requests without data.
    %w( get head ).each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def http_#{method}(path, params = nil)     # def http_get(path, params = nil)
          send_request('#{method}', path, params)  #   send_request('get', path)
        end                                        # end
      RUBY
    end

    # Create methods for easily sending HTTP requests with data.
    %w( post put delete ).each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def http_#{method}(path, data = nil)     # def http_post(path, data = nil)
          send_request('#{method}', path, data)  #   send_request('post', path, data)
        end                                      # end
      RUBY
    end

    # Returns whether the connection will append the format extension to URIs.
    #
    # @return [true, false]
    #
    def use_extension?
      @use_extension
    end

    #########
    protected
    #########

    # Sends an HTTP request to the remote server.
    #
    # @param [String] method
    #   The HTTP method to use when sending the request. One of get, post,
    #   put, delete, or head.
    # @param [String] path
    #   The request path.
    # @param [String] request_body
    #   Data to be sent with the request.
    #
    # @todo
    #   This should probably also preserve params which were set on the
    #   adapter's @uri.
    #
    def send_request(method, path, request_body = nil)
      request_uri, request_body =
        uri_for_request(@uri, method, path, request_body)

      response =
        Net::HTTP.start(@uri.host, @uri.port) do |http|
          # Retrieve the correct Net::HTTP class for performing the request.
          klass = Net::HTTP.const_get(DataMapper::Inflector.camelize(method))

          request = klass.new(request_uri.to_s, @format.headers)

          if @uri.user and @uri.password
            request.basic_auth(@uri.user, @uri.password)
          end

          http.request(request, request_body)
        end

      case response.code.to_i
        when 301, 302 then raise Redirection.new(response)
        when 200..399 then response
        when 400      then raise BadRequest.new(response)
        when 401      then raise UnauthorizedAccess.new(response)
        when 403      then raise ForbiddenAccess.new(response)
        when 404      then raise ResourceNotFound.new(response)
        when 405      then raise MethodNotAllowed.new(response)
        when 409      then raise ResourceConflict.new(response)
        when 422      then raise ResourceInvalid.new(response)
        when 406..499 then raise ClientError.new(response)
        when 500..599 then raise ServerError.new(response)
        else
          raise ConnectionError.new(
            response, "Unknown response code: #{response.code}")
      end
    end

    #######
    private
    #######

    # Creates an Addressable::URI for a single request.
    #
    # @param [Addressable::URI] base_uri
    #   The adapter's URI; the request URI will be based on this.
    # @param [String] method
    #   The HTTP method.
    # @param [String] path
    #   The request path.
    # @param [String] request_body
    #   Data to be sent with the request.
    #
    # @return [Array(Addressable::URI, String)]
    #   Returns a two-element tuple containing the URI for the request, and
    #   the data which should be sent with the request.
    #
    def uri_for_request(base_uri, method, path, request_body)
      # Don't alter the adapter's URI.
      request_uri = base_uri.dup

      if use_extension?
        request_uri.path = "#{path}.#{@format.extension}"
      else
        request_uri.path = path
      end

      return [ request_uri, nil ] if request_body.nil? or request_body.empty?

      case method
      when 'get', 'head'
        # GET and HEAD requests may provide a Hash of extra query parameters
        # which are appended to the end of the URL. Request bodies are not
        # permitted.
        unless request_body.kind_of?(Hash)
          raise "Cannot send request body with a #{method.upcase} request"
        end

        request_body = stringify_params(request_body)
        existing_query_values = request_uri.query_values || EMPTY_HASH

        request_uri.query_values = existing_query_values.merge(request_body)

        # Return the URI, and send no request body.
        [ request_uri, nil ]

      else
        # POST, PUT, and DELETE requests may supply a String of data to be
        # supplied as the request body.
        if request_body.kind_of?(Hash)
          raise "Cannot send params with a #{method.upcase} request"
        end

        [ request_uri, request_body.to_s ]

      end
    end # uri_for_request

    # Given a Hash of params, stringifies each value so that Addressable::URI
    # doesn't choke on them. Booleans are left alone, since URI knows how to
    # handle those.
    #
    def stringify_params(params)
      params.inject({}) do |memo, (key, value)|
        memo[key] = (value == true or value == false) ? value : value.to_s
        memo
      end
    end

  end # Connection
end # DataMapper::Rest
