module BeetleETL
  InvalidConfigurationError = Class.new(StandardError)

  class Configuration
    attr_accessor \
      :transformation_file,
      :stage_schema,
      :external_source,
      :logger

    attr_writer \
      :database,
      :database_config,
      :target_schema

    def initialize
      @target_schema = 'public'
      @logger = ::Logger.new(STDOUT)
    end

    def database
      if [@database, @database_config].none?
        msg = "Either Sequel connection database_config or a Sequel Database object required"
        raise InvalidConfigurationError.new(msg)
      end

      @database ||= Sequel.connect(@database_config)
    end

    def disconnect_database
      database.disconnect if @database_config
    end

    def target_schema
      @target_schema != 'public' ? @target_schema : nil
    end

  end
end
