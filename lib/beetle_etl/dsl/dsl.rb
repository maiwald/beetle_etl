module BeetleETL
  class DSL

    attr_reader :column_names, :relations, :query_string

    def initialize(table_name)
      @table_name = table_name
      @relations = {}
    end

    def columns(*column_names)
      @column_names = column_names
    end

    def references(foreign_table, on: foreign_key)
      @relations[on] = foreign_table
    end

    def query(query)
      @query_string = query
    end


    def stage_table
      BeetleETL::Naming.stage_table_name_sql(@table_name)
    end

    def external_source
      'source'
    end

    def combined_key(*args)
      %Q('[' || #{args.join(%q[ || '|' || ])} || ']')
    end

  end
end
