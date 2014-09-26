module BeetleETL
  class AssignIds < Step

    def dependencies
      [TableDiff.step_name(table_name)].to_set
    end

    def run
      assign_new_ids
      map_existing_ids
    end

    def assign_new_ids
      stage_table
        .where(
          import_run_id: run_id,
          transition: 'CREATE'
        )
        .update(
          id: Sequel.function(:NEXTVAL, "public.#{table_name}_id_seq")
        )
    end

    def map_existing_ids
      stage_table
        .from(stage_table_identifier, public_table_identifier)
        .where(
          stage__import_run_id: run_id,
          stage__transition: %w(KEEP UPDATE DELETE UNDELETE),
          stage__external_id: :public__external_id
        )
        .update(id: :public__id)
    end

    private

    def stage_table_identifier
      :"#{stage_schema}__#{table_name}___stage"
    end

    def stage_table
      database[stage_table_identifier]
    end

    def public_table_identifier
      :"#{table_name}___public"
    end

    def public_table
      database[public_table_identifier]
    end

  end
end
