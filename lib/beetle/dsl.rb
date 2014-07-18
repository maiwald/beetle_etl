module Beetle
  class DSL

    attr_reader :reference_config, :query_string

    def initialize
      @reference_config = {}
    end

    def references(foreign_table, on: foreign_key)
      @reference_config[on] = foreign_table
    end

    def query(query)
      @query_string = query
    end

  end
end
