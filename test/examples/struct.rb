require "representable/struct"

# Representing to_struct:
class Animal
  attr_accessor :name, :age, :species
  def initialize(name, age, species)
    @name = name
    @age = age
    @species = species
  end
end

class AnimalRepresenter < Representable::Decorator
  include Representable::Struct

  property :name, getter: ->(represented:, **) { represented.name.upcase }
  property :age
end

animal = Animal.new('Smokey',12,'c')
animal_repr = AnimalRepresenter.new(animal).to_struct(wrap: "wrapper")

animal_array = [Animal.new('Shepard',22,'s'),Animal.new('Pickle',12,'c'),Animal.new('Rodgers',55,'e')]
array_repr = AnimalRepresenter.for_collection.new(animal_array).to_struct

animal_klass = Struct.new("Animal", :name, :age, :species)
AnimalRepresenter.new(animal_klass.new("qwik", 12, "old")).to_struct(wrap: "wrapper")
