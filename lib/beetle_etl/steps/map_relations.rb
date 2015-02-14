module BeetleETL
  class MapRelations < Step

    def initialize(table_name, relations)
      super(table_name)
      @relations = relations
    end

    def dependencies
      @relations.values.map { |d| AssignIds.step_name(d) }.to_set << Transform.step_name(table_name)
    end

    def run
      @relations.map do |foreign_key_column, foreign_table_name|
        database.execute <<-SQL
          UPDATE #{stage_table_name_sql} current_table
          SET #{foreign_key_column} = foreign_table.id
          FROM #{stage_table_name_sql(foreign_table_name)} foreign_table
          WHERE current_table.external_#{foreign_key_column} = foreign_table.external_id
        SQL
      end
    end

  end
end
