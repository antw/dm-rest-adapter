require 'rexml/document'

module DataMapperRest
  module Formats
    # Provides support for XML resources over REST.
    class XML

      # Headers which are sent with each request to an XML resource.
      #
      # @return [Hash{String => String}]
      #
      def headers
        { 'Content-Type' => 'application/xml',
          'Accept'       => 'application/xml' }
      end

      # An extension appended to each URL requested.
      #
      # Temporary, hopefully. Content-Type/Accept should be the preferred way
      # of setting what we want the server to send.
      #
      # @return [String]
      #
      def extension
        'xml'
      end

      # Given a response body, transforms the attributes into a hash
      # containing the property names and typecast values.
      #
      # @param [Hash] attributes
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
        document = REXML::Document.new(response_body)
        res_name = adapter.resource_name(model)

        if element = REXML::XPath.first(document, "/#{res_name}")
          resource_from_rexml(element, model)
        else
          raise "No root element matching #{res_name} in XML"
        end
      end

      # Given a pre-parsed response body, iterates through each element and
      # creates a Resource instance.
      #
      # @param [Hash, Array] response_body
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
        elements = REXML::Document.new(response_body).elements

        col_name = adapter.collection_name(model)
        res_name = adapter.resource_name(model)

        elements.collect("/#{col_name}/#{res_name}") do |element|
          resource_from_rexml(element, model)
        end
      end

      # Given a resource, creates an XML representation suitable for sending
      # over the wire.
      #
      # @param [DataMapper::Resource] resource
      #   The resource to be serialized.
      #
      # @return [String]
      #   A XML representation of the resource.
      #
      def serialize_resource(resource)
        resource.to_xml
      end

      #######
      private
      #######

      # Given a REXML node, extracts the properties into a Hash.
      #
      # @param [REXML::Element] entity_element
      #   A REXML element containing attributes for a resource.
      # @param [DataMapper::Model] model
      #   The DataMapper model whose attributes are in +entity_element+.
      #
      # @return [Hash{String => Object}]
      #   A hash of properties defined on the model and the values present
      #   in the given XML element(s).
      #
      def resource_from_rexml(entity_element, model)
        attributes = Hash.new

        entity_element.elements.each do |element|
          # TODO Should be part of the NamingConventions.
          field = element.name.to_s.tr('-', '_')

          if property = model.properties[field]
            attributes[field] = property.typecast(element.text)
          end
        end

        attributes
      end

    end # XML
  end # Formats
end # DataMapperRest
