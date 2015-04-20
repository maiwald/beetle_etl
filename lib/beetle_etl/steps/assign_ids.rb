module BeetleETL
  class AssignIds < Step

    def dependencies
      [TableDiff.step_name(table_name)].to_set
    end

    def run
      database.execute <<-SQL
        UPDATE #{stage_table_name_sql} stage_update
        SET id = COALESCE(public.id, nextval('#{table_name}_id_seq'))
        FROM #{stage_table_name_sql} stage
        LEFT OUTER JOIN #{public_table_name_sql} public
          on (
            stage.external_id = public.external_id
            AND public.external_source = '#{external_source}'
          )
        WHERE stage_update.external_id = stage.external_id
      SQL
    end

  end
end
