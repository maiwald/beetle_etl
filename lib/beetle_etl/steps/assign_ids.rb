module BeetleETL
  class AssignIds < Step

    def dependencies
      [TableDiff.step_name(table_name)].to_set
    end

    def run
      database.execute <<-SQL
        UPDATE "#{target_schema}"."#{stage_table_name}" stage_update
        SET id = COALESCE(target.id, NEXTVAL(pg_get_serial_sequence('#{target_schema}.#{table_name}', 'id')))
        FROM "#{target_schema}"."#{stage_table_name}" stage
        LEFT OUTER JOIN "#{target_schema}"."#{table_name}" target
          on (
            stage.external_id = target.external_id
            AND target.external_source = '#{external_source}'
          )
        WHERE stage_update.external_id = stage.external_id
      SQL
    end

  end
end
