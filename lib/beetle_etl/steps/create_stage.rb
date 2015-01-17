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
        CREATE TEMPORARY TABLE #{stage_table_name_sql} (
          id integer,
          external_id character varying(255),

          #{payload_column_definitions},
          #{relation_column_definitions}
        )
      SQL
    end

    private

    def payload_column_definitions
      (@column_names - @relations.keys).map do |column_name|
        "#{column_name} #{column_type(column_name)}"
      end.join(',')
    end

    def relation_column_definitions
      @relations.map do |foreign_key_name, table|
        <<-SQL
          #{foreign_key_name} integer,
          external_#{foreign_key_name} character varying(255)
        SQL
      end.join(',')
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
