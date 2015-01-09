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
      database.create_schema stage_schema, if_not_exists: true

      database.execute <<-SQL
        CREATE TABLE #{stage_table_name} (
          id integer,
          external_id character varying(255),

          #{payload_column_definitions}
        )
      SQL
    end

    private

    def payload_column_definitions
      @column_names.map do |column_name|
        "#{column_name} #{column_type(column_name)}"
      end.join(',')
    end

    def column_type(column_name)
      @column_types ||= Hash[database.schema(:"#{public_schema}__#{table_name}")]
        .reduce({}) do |acc, (name, schema)|
          acc[name.to_sym] = schema.fetch(:db_type)
          acc
        end

      @column_types[column_name]
    end

  end
end
