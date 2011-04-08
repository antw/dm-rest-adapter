require 'json'

module DataMapperRest
  module Formats
    # Provides support for JSON resources over REST.
    class JSON

      # Headers which are sent with each request to an JSON resource.
      #
      # @return [Hash{String => String}]
      #
      def headers
        { 'Content-Type' => 'application/json',
          'Accept'       => 'application/json' }
      end

      # An extension appended to each URL requested.
      #
      # Temporary, hopefully. Content-Type/Accept should be the preferred way
      # of setting what we want the server to send.
      #
      # @return [String]
      #
      def extension
        'json'
      end

      # Given a response body, transforms the attributes in the given hash
      # into a hash containing the property names and typecast values.
      #
      # @param [String] attributes
      #   The attributes to be assigned to the resource.
      # @param [DataMapper::Model] model
      #   The model whose resources are to be extracted for the response_body.
      #   For example, if the response body contains a collection of books,
      #   the model would be Book.
      # @param [Adapter] adapter
      #   The adapter. Required in order to find the collection and resource
      #   names.
      #
      # @return [Hash{String => Object}]
      #   Parsed attributes for a resource.
      #
      def resource(response_body, model, adapter)
        resource_from_json(::JSON.parse(response_body), model) or
          raise "No root element matching #{res_name} in JSON"
      end

      # Given a response body (expected to be a JSON array), iterates through
      # each element and creates a Resource instance.
      #
      # @param [String] response_body
      #   The body returned by the web service.
      # @param [DataMapper::Model] model
      #   The model whose resources are to be extracted for the response_body.
      #   For example, if the response body contains a collection of books,
      #   the model would be Book.
      # @param [Adapter] adapter
      #   The adapter. Required in order to find the collection and resource
      #   names.
      #
      # @return [Array(Hash{String => Object})]
      #   An array of hashes containing parsed attributes for one or more
      #   resources.
      #
      def resources(response_body, model, adapter)
        ::JSON.parse(response_body).map do |element|
          resource_from_json(element, model)
        end
      end

      # Given a response body (expected to be a JSON object), converts the
      # body into a Hash of errors keyed on each property.
      #
      # @param [String] response_body
      #   The body returned by the web service.
      #
      # @return [Hash{String => Array(String)}]
      #
      def errors(response_body)
        ::JSON.parse(response_body)
      end

      # Given a resource, creates a JSON representation suitable for sending
      # over the wire.
      #
      # @param [DataMapper::Resource] resource
      #   The resource to be serialized.
      #
      # @return [String]
      #   A JSON representation of the resource.
      #
      def serialize_resource(resource)
        resource.to_json
      end

      #######
      private
      #######

      # Given a hash of property/values from parsing the JSON response,
      # extracts the properties into a Hash keyed on property name, with
      # each value being typcast by the property.
      #
      # @param [Hash{String => String}] entity_element
      #   A hash containing attributes for a resource.
      # @param [DataMapper::Model] model
      #   The DataMapper model whose attributes are in +entity_element+.
      #
      # @return [Hash{String => Object}]
      #   A hash of properties defined on the model and the typecast values.
      #
      def resource_from_json(entity_element, model)
        attributes = Hash.new

        entity_element.each_pair do |key, value|
          # TODO Should be part of the NamingConventions.
          field = key.to_s.tr('-', '_')

          if property = model.properties[field]
            attributes[field] = property.typecast(value)
          end
        end

        attributes
      end

    end # JSON
  end # Formats
end # DataMapperRest
