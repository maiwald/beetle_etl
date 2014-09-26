require 'set'

module BeetleETL
  class Transformation

    attr_reader :table_name

    def initialize(table_name, setup)
      @table_name = table_name
      (@parsed = DSL.new(table_name)).instance_eval(&setup)
    end

    def relations
      @parsed.relations
    end

    def dependencies
      relations.values.to_set
    end

    def query
      @parsed.query_string
    end

  end
end
