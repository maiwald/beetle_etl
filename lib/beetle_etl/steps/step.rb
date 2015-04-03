module BeetleETL

  class Step

    include BeetleETL::Naming
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
      Set.new
    end

    def external_source
      BeetleETL.config.external_source
    end

    def database
      BeetleETL.database
    end

  end
end
