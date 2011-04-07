module DataMapperRest
  module Spec
    module FormatHelpers

      # Provides the ability to wrap examples and groups in a +with_formats+
      # block to run the examples once for each format.
      #
      def with_formats(*formats, &block)
        unless Thread.current[:rest_format].nil?
          raise "with_format blocks cannot be nested"
        end

        formats.each do |format|

          DataMapper.repository(:rest_format) do
            describe("With #{format}:") do
              before(:all) { set_format(format) }
              after(:all)  { reset_format! }

              instance_eval(&block)
            end
          end

        end
      end

      # Returns the current format name.
      #
      # @return [String]
      #
      def current_format
        Thread.current[:rest_format]
      end

      # Sets the format for the examples.
      #
      def set_format(format)
        Thread.current[:rest_format] =
          case format
            when 'xml'  then DataMapperRest::Formats::XML.new
            when 'json' then DataMapperRest::Formats::JSON.new
            else             raise "Unknown format: #{format}"
          end

        DataMapper.setup(:default,
          "rest://admin:secret@localhost:4000/?format=#{format}")
      end

      # Reverts to the default adapter.
      #
      def reset_format!
        set_format('xml')
      end

    end # FormatHelpers
  end # Spec
end # DataMapperRest
