module BeetleETL
  class MapRelations < Step

    def initialize(config, table_name, relations)
      super(config, table_name)
      @relations = relations
    end

    def dependencies
      result = Set.new([Transform.step_name(table_name)])
      result.merge @relations.values.map { |d| TableDiff.step_name(d) }
    end

    def run
      @relations.map do |foreign_key_column, foreign_table_name|
        database.execute <<-SQL
          UPDATE "#{target_schema}"."#{stage_table_name}" current_table
          SET #{foreign_key_column} = foreign_table.id
          FROM "#{target_schema}"."#{stage_table_name(foreign_table_name)}" foreign_table
          WHERE current_table.external_#{foreign_key_column} = foreign_table.external_id
        SQL
      end
    end

  end
end
