module DataMapperRest
  # Provides a DataMapper adapter supporting retrieving and persisting
  # resources over a REST API to a remote server.
  #
  # TODO: Abstract XML support out from the protocol
  # TODO: Build JSON support
  #
  class Adapter < DataMapper::Adapters::AbstractAdapter

    # For each model instance in resources, issues a POST request to create a
    # new record in the data store for the instance
    #
    # @param [Enumerable(Resource)] resources
    #   The list of resources (model instances) to create.
    #
    # @return [Integer]
    #   The number of records that were actually saved into the database.
    #
    # @api semipublic
    #
    def create(resources)
      resources.each do |resource|
        response = connection.http_post(
          collection_name(resource.model),
          connection.format.serialize_resource(resource))

        update_with_response(resource, response)
      end

      resources.length
    end

    # Retrieves resources over HTTP (i.e., an SQL select), returning an array
    # of Hashes, with each hash containing attributes for a single resource.
    #
    # @param [Query] query
    #   Composition of the query to perform.
    #
    # @return [Array]
    #   Result set of the query.
    #
    # @api semipublic
    #
    def read(query)
      model = query.model

      records =
        if id = extract_id_from_query(query)
          # When a key is present, fetch the single resource directly.
          response = connection.http_get("#{collection_name(model)}/#{id}")
          [ connection.format.resource(response.body, model, self) ]
        else
          # When no key is present, we instead fetch the collection.
          params   = params_as_uri_string(extract_params_from_query(query))
          response = connection.http_get("#{collection_name(model)}#{params}")

          connection.format.resources(response.body, model, self)
        end

      query.filter_records(records)
    end

    # For each model instance in the collection, issues a PUT request to
    # update the resources with their new attributes.
    #
    # @param [Hash(Property => Object)] attributes
    #   Hash of attribute values to set, keyed by Property.
    # @param [Collection] collection
    #   Collection of records to be updated.
    #
    # @return [Integer]
    #   The number of records updated.
    #
    # @api semipublic
    #
    def update(dirty_attributes, collection)
      collection.select do |resource|
        model = resource.model
        id    = model.key.get(resource).join

        dirty_attributes.each { |prop, value| prop.set!(resource, value) }

        response = connection.http_put(
          "#{collection_name(model)}/#{id}",
          connection.format.serialize_resource(resource))

        update_with_response(resource, response)
      end.size
    end

    # Deletes one or more resources.
    #
    # @param [Collection] collection
    #   Collection of records to be deleted.
    #
    # @return [Integer]
    #   The number of records successfully deleted.
    #
    # @api semipublic
    #
    def delete(collection)
      collection.select do |resource|
        model = resource.model
        id    = model.key.get(resource).join

        response = connection.http_delete("#{collection_name(model)}/#{id}")
        response.kind_of?(Net::HTTPSuccess)
      end.size
    end

    # Given a model, determines what key a collection of resources arestored
    # in within a response body.
    #
    # @return [String]
    #
    def collection_name(model)
      model.storage_name(name)
    end

    # Given a model, determines what key each resource is stored in.
    #
    # @return [String]
    #
    def resource_name(model)
      DataMapper::Inflector.singularize(collection_name(model))
    end

    #######
    private
    #######

    def initialize(*)
      super
      @format = @options.fetch(:format, 'xml')
    end

    def connection
      @connection ||= Connection.new(normalized_uri, @format)
    end

    def normalized_uri
      @normalized_uri ||=
        begin
          query = @options.except(:adapter, :user, :password, :host, :port, :path, :fragment)
          query = nil if query.empty?

          Addressable::URI.new(
            :scheme       => 'http',
            :user         => @options[:user],
            :password     => @options[:password],
            :host         => @options[:host],
            :port         => @options[:port],
            :path         => @options[:path],
            :query_values => query,
            :fragment     => @options[:fragment]
          ).freeze
        end
    end

    def extract_id_from_query(query)
      return nil unless query.limit == 1

      conditions = query.conditions

      return nil unless conditions.kind_of?(DataMapper::Query::Conditions::AndOperation)
      return nil unless (key_condition = conditions.select { |o| o.subject.key? }).size == 1

      key_condition.first.value
    end

    def extract_params_from_query(query)
      conditions = query.conditions

      return {} unless conditions.kind_of?(DataMapper::Query::Conditions::AndOperation)
      return {} if conditions.any? { |o| o.subject.key? }

      query.options
    end

    # Updates a resource with attributes returned by the server.
    #
    # @param [DataMapper::Resource] resource
    #   The resource whose attributes are to be updated.
    # @param [Net::HTTPSuccess]
    #   The response returned by the server.
    #
    def update_with_response(resource, response)
      # @todo Is the Net::HTTPSuccess check required? Won't failing requests
      #       raise an exception, preventing us ever arriving here?
      return unless response.kind_of?(Net::HTTPSuccess) and
                    not DataMapper::Ext.blank?(response.body)

      model      = resource.model
      properties = model.properties(name)
      attributes = connection.format.resource(response.body, model, self)

      attributes.each do |key, value|
        if property = properties[key] then property.set!(resource, value) end
      end
    end

    # Given an hash of params, formats and escapes them for use in a URI
    # string.
    #
    # @param [Hash] params The parameters to be formatted
    # @return [String]
    #
    def params_as_uri_string(params)
      return '' if params.length == 0

      '?%s' % params.map do |key, value|
        "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
      end.join('&')
    end

  end # Adapter
end # DataMapperRest
