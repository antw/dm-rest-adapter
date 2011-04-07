module DataMapperRest
  # Performs HTTP requests.
  #
  # @todo Support HTTPS.
  # @todo Handle nested resources, see prefix in ActiveResource.
  #
  class Connection
    attr_accessor :uri, :format

    # Creates a new Connection instance (does not connect to the remote server
    # when initialized).
    #
    # @param [Addressable::URI] uri
    #   The URI supplied to DataMapper.setup(...) containing the base address
    #   for requests, port, protocol, etc.
    # @param [String] format
    #   The format to be used when making requests (currently not used).
    #
    def initialize(uri, format)
      @uri = uri
      @format = Formats::XML.new
    end

    # Create methods for easily sending HTTP requests without data.
    %w( get head ).each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def http_#{method}(path)                 # def http_get(path)
          send_request('#{method}', path)        #   send_request('get', path)
        end                                      # end
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

    #########
    protected
    #########

    # Sends an HTTP request to the remote server.
    #
    # @param [String] method
    #   The HTTP method to use when sending the request. One of get, post,
    #   put, delete, or head.
    # @param [String] request_body
    #   Data to be sent with the request.
    #
    # @todo
    #   This should probably also preserve params which were set on the
    #   adapter's @uri.
    #
    def send_request(method, path, data = nil)
      response = nil

      # A copy of the repository's URI with a full path set.
      request_uri = @uri.dup

      # Add the format to the URL, before the params (indicated with a ?), or
      # at the end if there are no parameters.
      #
      # @todo Get rid of this; format should be set using the
      # Content-Type and Accept header.
      #
      request_uri.path = path.sub(/(\?|$)/, ".#{@format.extension}\\1")

      response =
        Net::HTTP.start(@uri.host, @uri.port) do |http|
          # Retrieve the correct Net::HTTP class for performing the request.
          klass = Net::HTTP.const_get(DataMapper::Inflector.camelize(method))

          request = klass.new(request_uri.to_s, @format.headers)

          if @uri.user and @uri.password
            request.basic_auth(@uri.user, @uri.password)
          end

          http.request(request, data)
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

  end
end
