# frozen_string_literal: true

module Representable::Represent
  def represent(represented, array_class=Array)
    return for_collection.prepare(represented) if represented.is_a?(array_class)

    prepare(represented)
  end
end
