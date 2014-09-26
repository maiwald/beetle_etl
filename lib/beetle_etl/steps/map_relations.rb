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
      relations.each do |foreign_key_column, foreign_table_name|
        database.from(
          :"#{stage_schema}__#{table_name}___ST",
          :"#{stage_schema}__#{foreign_table_name}___FT"
        ).where(
          ST__import_run_id: run_id,
          FT__import_run_id: run_id,
          FT__external_id: :"ST__external_#{foreign_key_column}",
        ).update(
          :"#{foreign_key_column}" => :"FT__id"
        )
      end
    end

  end
end
