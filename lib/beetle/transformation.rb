require 'set'

module Beetle
  class Transformation

    attr_reader :table_name

    def initialize(table_name, setup)
      @table_name = table_name
      (@parsed = DSL.new).instance_eval(&setup)
    end

    def references
      @parsed.reference_config
    end

    def dependencies
      @parsed.reference_config.values.to_set
    end

    def query
      @parsed.query_string
    end

  end
end
