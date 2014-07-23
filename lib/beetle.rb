require 'beetle/version'

module Beetle

  require 'beetle/state'
  require 'beetle/dsl'
  require 'beetle/transformation'
  require 'beetle/transformation_loader'
  require 'beetle/dependency_resolver'

  require 'beetle/transform/table_diff'
  require 'beetle/import'

  class Configuration
    attr_accessor \
      :database_config,
      :database,
      :transformation_file,
      :stage_schema,
      :external_source

    def initialize
      @stage_schema = 'stage'
    end
  end

  class << self

    def import
      state.start_import

      begin
        Import.run
        state.mark_as_succeeded
      rescue Exception => e
        state.mark_as_failed
        raise e
      ensure
        @database.disconnect if @database
      end
    end

    def configure
      yield(config)
    end

    def config
      @config ||= Configuration.new
    end

    def database
      if config.database
        config.database
      else
        @database ||= Sequel.connect(config.database_config)
      end
    end

    def state
      @state ||= State.new
    end

    def reset
      @config = nil
      @state = nil
      @database = nil
    end

  end
end
