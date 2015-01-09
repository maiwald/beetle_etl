module BeetleETL

  DependenciesNotDefinedError = Class.new(StandardError)

  class Step

    attr_reader :table_name

    def initialize(table_name)
      @table_name = table_name
    end

    def self.step_name(table_name)
      "#{table_name}: #{name.split('::').last}"
    end

    def name
      self.class.step_name(table_name)
    end

    def dependencies
      raise DependenciesNotDefinedError
    end

    def stage_table_name
      %Q("#{stage_schema}"."#{table_name}")
    end

    def public_table_name
      %Q("#{public_schema}"."#{table_name}")
    end

    def run_id
      BeetleETL.state.run_id
    end

    def stage_schema
      BeetleETL.config.stage_schema
    end

    def public_schema
      BeetleETL.config.public_schema
    end

    def external_source
      BeetleETL.config.external_source
    end

    def database
      BeetleETL.database
    end

  end
end
