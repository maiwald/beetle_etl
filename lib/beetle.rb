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
      :transformation_file,
      :import_run_id,
      :stage_schema,
      :external_source

    def initialize
      @stage_schema = 'stage'
    end
  end

  class << self

    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
    end

    def import
    end

    private

    def transformations
      transformations = TransformationLoader.load
      DependencyResolver.resolve(transformations)
    end

  end
end
