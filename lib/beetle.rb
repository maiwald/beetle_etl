require 'beetle/version'

module Beetle

  require 'beetle/dsl'
  require 'beetle/transformation'
  require 'beetle/transformation_loader'
  require 'beetle/dependency_resolver'

  class Configuration
    attr_accessor \
      :database_config,
      :database,
      :transformation_file
  end

  class << self

    def import(config)
      transformations = TransformationLoader.load(config.transformation_file)
      ordered_transformations = DependencyResolver.resolve(transformations)
      ordered_transformations.each do |transformation|
        config.database.run(transformation.query)
      end
    end

  end
end
