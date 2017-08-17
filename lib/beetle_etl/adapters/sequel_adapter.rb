module BeetleETL
  class SequelAdapter
    attr_reader :database
    def initialize(database)
      @database = database
    end

    def execute(query)
      @database.run(query)
    end

    def column_names(schema_name, table_name)
      @database[Sequel.qualify(schema_name, table_name)].columns
    end

    def column_types(schema_name, table_name)
      Hash[@database.schema(Sequel.qualify(schema_name, table_name))].reduce({}) do |acc, (name, column_config)|
        acc[name.to_sym] = column_config.fetch(:db_type)
        acc
      end
    end

    def table_exists?(schema_name, table_name)
      @database.table_exists?(Sequel.qualify(schema_name, table_name))
    end

    def transaction(&block)
      @database.transaction(&block)
    end

    def disconnect
      @database.disconnect
    end
  end
end
