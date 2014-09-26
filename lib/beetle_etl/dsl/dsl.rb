module BeetleETL
  class DSL

    attr_reader :relations, :query_string

    def initialize(table_name)
      @table_name = table_name
      @relations = {}
    end

    def references(foreign_table, on: foreign_key)
      @relations[on] = foreign_table
    end

    def query(query)
      @query_string = query
    end


    def stage_table
      %Q("#{BeetleETL.config.stage_schema}"."#{@table_name}")
    end

    def external_source
      'source'
    end

    def combined_key(*args)
      %Q('[' || #{args.join(%q[ || ',' || ])} || ']')
    end

    def import_run_id
      BeetleETL.state.run_id
    end

  end
end
