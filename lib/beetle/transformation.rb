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
      @parsed.reference_config.values
    end

    def query
      @parsed.query_string
    end

    private

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

      def external_source
        'my_source'
      end

      def run_id
        1
      end
    end

  end
end
