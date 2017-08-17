module BeetleETL

  InvalidConfigurationError = Class.new(StandardError)

  class Configuration
    attr_accessor \
      :transformation_file,
      :target_schema,
      :stage_schema,
      :external_source,
      :logger

    attr_writer \
      :database,
      :database_config

    def initialize
      @target_schema = 'public'
      @logger = ::Logger.new(STDOUT)
    end

    def database=(database)
      @database_config = nil
      @adapter ||= case
        when sequel?(database) then SequelAdapter.new(database)
        else nil
      end
    end

    def database_config=(database_config)
      @database_config = database_config
      @adapter = SequelAdapter.new(Sequel.connect(@database_config))
    end

    def database
      if @adapter.nil?
        msg = "Either Sequel connection database_config, Sequel::Database object or ActiveRecord::Base.connection required!"
        raise InvalidConfigurationError.new(msg)
      end

      @adapter
    end

    def disconnect_database
      @adapter.disconnect if @database_config
    end

    private

    def sequel?(database)
      defined?(::Sequel::Database) && database.is_a?(::Sequel::Database)
    end

  end
end
