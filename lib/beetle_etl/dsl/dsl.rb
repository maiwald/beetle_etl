module BeetleETL
  class DSL

    attr_reader :column_names, :relations, :query_strings

    def initialize(config, table_name)
      @config = config
      @table_name = table_name
      @column_names = []
      @relations = {}
      @query_strings = []
    end

    def columns(*column_names)
      @column_names = column_names
    end

    def references(foreign_table, on: foreign_key)
      @relations[on] = foreign_table
    end

    def query(query)
      @query_strings << query
    end

    # query helper methods

    def stage_table(table_name = nil)
      BeetleETL::Naming.stage_table_name_sql(
        @config.external_source,
        table_name || @table_name
      )
    end

    def combined_key(*args)
      %Q('[' || #{args.join(%q[ || ',' || ])} || ']')
    end

  end
end
