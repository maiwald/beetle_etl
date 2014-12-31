module BeetleETL
  class MapRelations < Step

    attr_reader :relations

    def initialize(table_name, relations)
      super(table_name)
      @relations = relations
    end

    def dependencies
      relations.values.map { |d| AssignIds.step_name(d) }.to_set << Transform.step_name(table_name)
    end

    def run
      relations.map do |foreign_key_column, foreign_table_name|
        database.execute <<-SQL
          UPDATE #{stage_table_name} current_table
          SET #{foreign_key_column} = foreign_table.id
          FROM "#{stage_schema}"."#{foreign_table_name}" foreign_table
          WHERE current_table.external_#{foreign_key_column} = foreign_table.external_id
          AND current_table.import_run_id = #{run_id}
          AND foreign_table.import_run_id = #{run_id}
        SQL
      end
    end

    private

    def stage_table_name
      %Q("#{stage_schema}"."#{table_name}")
    end

  end
end
