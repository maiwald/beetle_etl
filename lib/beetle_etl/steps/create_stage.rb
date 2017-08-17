module BeetleETL

  ColumnDefinitionNotFoundError = Class.new(StandardError)
  NoColumnsDefinedError = Class.new(StandardError)

  class CreateStage < Step

    def initialize(config, table_name, relations, column_names)
      super(config, table_name)
      @relations = relations
      @column_names = column_names
    end

    def run
      database.execute <<-SQL
        CREATE UNLOGGED TABLE IF NOT EXISTS "#{target_schema}"."#{stage_table_name}" (
          id integer,
          external_id character varying(255),
          transition character varying(255),

          #{column_definitions}
        );

        #{index_definitions};

        ALTER TABLE "#{target_schema}"."#{stage_table_name}"
        SET (
          autovacuum_enabled = false,
          toast.autovacuum_enabled = false
        );

        TRUNCATE TABLE "#{target_schema}"."#{stage_table_name}" RESTART IDENTITY CASCADE;
      SQL
    end

    private

    def column_definitions
      definitions = [
        payload_column_definitions,
        relation_column_definitions
      ].flatten

      if definitions.empty?
        raise NoColumnsDefinedError.new <<-MSG
          Transformation for #{table_name} has no column definitions.
          Either add an array of columns or references to other tables.
        MSG
      end

      definitions.join(',')
    end

    def payload_column_definitions
      (@column_names - @relations.keys).map do |column_name|
        "#{column_name} #{column_type(column_name)}"
      end
    end

    def relation_column_definitions
      @relations.map do |foreign_key_name, table|
        <<-SQL
          #{foreign_key_name} integer,
          external_#{foreign_key_name} character varying(255)
        SQL
      end
    end

    def index_definitions
      index_columns = [:external_id] + @relations.keys.map { |c| "external_#{c}" }
      index_columns.map do |column_name|
        %Q[CREATE INDEX ON "#{target_schema}"."#{stage_table_name}" (#{column_name});]
      end.join(";")
    end

    def column_type(column_name)
      @column_types ||= database.column_types(target_schema, table_name)

      unless @column_types.has_key?(column_name)
        raise ColumnDefinitionNotFoundError.new <<-MSG
          Table "#{table_name}" has no column "#{column_name}".
        MSG
      end

      @column_types[column_name]
    end

  end
end
