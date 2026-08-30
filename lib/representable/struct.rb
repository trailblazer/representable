require 'representable'
require 'representable/struct/binding'

module Representable
  module Struct
    autoload :Collection, 'representable/struct/collection'

    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
        register_feature Representable::Struct
      end
    end


    module ClassMethods
      def format_engine
        Representable::Struct
      end

      def collection_representer_class
        Collection
      end

      def cache_struct
        @represented_struct ||= ::Struct.new(*representable_attrs.keys.map(&:to_sym))
      end

      def cache_wrapper_struct(wrap:)
        struct_name = :"@_wrapper_struct_#{wrap}"
        return instance_variable_get(struct_name) if instance_variable_defined?(struct_name)

        instance_variable_set(struct_name, ::Struct.new(wrap))
      end
    end

    def to_struct(options={}, binding_builder=Binding)
      represented_struct = self.class.cache_struct

      object = create_representation_with(represented_struct.new, options, binding_builder)
      return object if options[:wrap] == false
      return object unless (wrap = options[:wrap] || representation_wrap(options))

      wrapper_struct = self.class.cache_wrapper_struct(wrap: wrap.to_sym)
      wrapper_struct.new(object)
    end
  end
end
