module BeetleETL

  class Step

    attr_reader :table_name
    attr_accessor :started_at, :finished_at

    def run
      raise NotImplementedError
    end

    def initialize(config, table_name)
      @config = config
      @table_name = table_name
    end

    def self.step_name(table_name)
      "#{table_name}: #{name.split('::').last}"
    end

    def name
      self.class.step_name(table_name)
    end

    def dependencies
      Set.new
    end

    def external_source
      @config.external_source
    end

    def database
      @config.database
    end

    def target_schema
      @config.target_schema
    end

    def stage_table_name(table_name = nil)
      BeetleETL::Naming.stage_table_name(external_source, table_name || @table_name)
    end

  end
end
