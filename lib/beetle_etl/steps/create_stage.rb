module BeetleETL
  class CreateStage < Step

    def initialize(table_name, relations, column_names)
      super(table_name)
      @relations = relations
      @column_names = column_names
    end

    def dependencies
      Set.new
    end

    def run
      database.execute <<-SQL
        CREATE UNLOGGED TABLE #{stage_table_name_sql} (
          id integer,
          external_id character varying(255),
          transition character varying(255),

          #{[
            payload_column_definitions,
            relation_column_definitions
          ].compact.join(',')}
        );

        #{index_definitions}
      SQL
    end

    private

    def payload_column_definitions
      definitions = (@column_names - @relations.keys).map do |column_name|
        "#{column_name} #{column_type(column_name)}"
      end
      definitions.join(',') if definitions.any?
    end

    def relation_column_definitions
      definitions = @relations.map do |foreign_key_name, table|
        <<-SQL
          #{foreign_key_name} integer,
          external_#{foreign_key_name} character varying(255)
        SQL
      end
      definitions.join(',') if definitions.any?
    end

    def index_definitions
      index_columns = [:external_id] + @relations.keys.map { |c| "external_#{c}" }
      index_columns.map do |column_name|
        "CREATE INDEX ON #{stage_table_name_sql} (#{column_name})"
      end.join(";")
    end

    def column_type(column_name)
      @column_types ||= Hash[database.schema(public_table_name.to_sym)]
        .reduce({}) do |acc, (name, schema)|
          acc[name.to_sym] = schema.fetch(:db_type)
          acc
        end

      @column_types[column_name]
    end

  end
end
