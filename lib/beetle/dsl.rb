module Beetle
  class DSL

    attr_reader :reference_config, :query_string

    def initialize(table_name)
      @table_name = table_name
      @reference_config = {}
    end

    def references(foreign_table, on: foreign_key)
      @reference_config[on] = foreign_table
    end

    def query(query)
      @query_string = query
    end


    def stage_table
      %Q("#{Beetle.config.stage_schema}"."#{@table_name}")
    end

    def external_source
      'source'
    end

    def combined_key(*args)
      %Q('[' || #{args.join(%q[ || ',' || ])} || ']')
    end

    def import_run_id
      Beetle.state.import_run_id
    end

  end
end
