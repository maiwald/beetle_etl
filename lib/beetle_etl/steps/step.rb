module BeetleETL

  class Step

    attr_reader :table_name

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

    # naming

    def stage_table_name
      BeetleETL::Naming.stage_table_name(@config.external_source, @table_name)
    end

    def stage_table_name_sql(table_name = nil)
      table_name ||= @table_name
      BeetleETL::Naming.stage_table_name_sql(@config.external_source, table_name)
    end

    def target_table_name
      BeetleETL::Naming.target_table_name(@config.target_schema, @table_name)
    end

    def target_table_name_sql
      BeetleETL::Naming.target_table_name_sql(@config.target_schema, @table_name)
    end

  end
end
