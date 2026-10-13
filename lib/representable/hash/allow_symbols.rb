# frozen_string_literal: true

module Representable
  module Hash
    module AllowSymbols
      private

      def filter_wrap_for(data, *args)
        super(Conversion.stringify_keys(data), *args)
      end

      def update_properties_from(data, *args)
        super(Conversion.stringify_keys(data), *args)
      end
    end

    module Conversion
      def self.stringify_keys(hash)
        result = {}
        hash.each do |key, value|
          result[key.to_s] = value
        end
        result
      end
    end
  end
end
