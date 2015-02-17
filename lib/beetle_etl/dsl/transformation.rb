require 'set'

module BeetleETL
  class Transformation

    attr_reader :table_name

    def initialize(table_name, setup, helpers = nil)
      @table_name = table_name
      @parsed = DSL.new(table_name).tap do |dsl|
        dsl.instance_eval(&helpers) if helpers
        dsl.instance_eval(&setup)
      end
    end

    def column_names
      @parsed.column_names.map(&:to_sym)
    end

    def relations
      @parsed.relations
    end

    def dependencies
      relations.values.to_set
    end

    def query
      @parsed.query_strings.join(';')
    end

  end
end
