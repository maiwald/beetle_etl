require "beetle/version"

module Beetle

  require 'beetle/dsl'
  require 'beetle/transformation'
  require 'beetle/transformation_loader'
  require 'beetle/dependency_resolver'

  extend self

  def import(transformations_file)
    transformations = TransformationLoader.load(transformations_file)
    ordered_transformations = DependencyResolver.resolve(transformations)
    ordered_transformations
  end

end
