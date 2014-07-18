require "beetle/version"

module Beetle

  require 'beetle/dsl'
  require 'beetle/transformation'
  require 'beetle/transformation_loader'

  extend self

  def import(transformations_file)
    transformations = TransformationLoader.load(transformations_file)
    transformations
  end

end
