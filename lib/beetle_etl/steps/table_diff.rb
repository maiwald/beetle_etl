module BeetleETL
  class TableDiff < Step

    IMPORTER_COLUMNS = %i[
      external_id
      transition
    ]

    def dependencies
      [MapRelations.step_name(table_name)].to_set
    end

    def run
      %w(create update delete reinstate keep).each do |transition|
        public_send(:"transition_#{transition}")
      end
    end

    def transition_create
      database.execute <<-SQL
        UPDATE "#{target_schema}"."#{stage_table_name}" stage
        SET
          transition = 'CREATE',
          id = NEXTVAL('#{target_schema}.#{table_name}_id_seq')
        WHERE NOT EXISTS (
          SELECT 1
          FROM "#{target_schema}"."#{table_name}" target
          WHERE target.external_id = stage.external_id
          AND target.external_source = '#{external_source}'
        )
      SQL
    end

    def transition_update
      database.execute <<-SQL
        UPDATE "#{target_schema}"."#{stage_table_name}" stage_update
        SET
          transition = 'UPDATE',
          id = target.id
        FROM "#{target_schema}"."#{stage_table_name}" stage
        JOIN "#{target_schema}"."#{table_name}" target ON (
          target.external_id = stage.external_id
          AND target.external_source = '#{external_source}'
          AND target.deleted_at IS NULL
          AND
            (#{target_record_columns.join(', ')})
            IS DISTINCT FROM
            (#{stage_record_columns.join(', ')})
        )
        WHERE stage_update.external_id = stage.external_id
      SQL
    end

    def transition_delete
      database.execute <<-SQL
        INSERT INTO "#{target_schema}"."#{stage_table_name}"
          (transition, id)
        SELECT
          'DELETE',
          target.id
        FROM "#{target_schema}"."#{table_name}" target
        LEFT OUTER JOIN "#{target_schema}"."#{stage_table_name}" stage
          ON (stage.external_id = target.external_id)
        WHERE stage.external_id IS NULL
        AND target.external_source = '#{external_source}'
        AND target.deleted_at IS NULL
      SQL
    end

    def transition_reinstate
      database.execute <<-SQL
        UPDATE "#{target_schema}"."#{stage_table_name}" stage_update
        SET
          transition = 'REINSTATE',
          id = target.id
        FROM "#{target_schema}"."#{stage_table_name}" stage
        JOIN "#{target_schema}"."#{table_name}" target ON (
          target.external_id = stage.external_id
          AND target.external_source = '#{external_source}'
          AND target.deleted_at IS NOT NULL
        )
        WHERE stage_update.external_id = stage.external_id
      SQL
    end

    def transition_keep
      database.execute <<-SQL
        UPDATE "#{target_schema}"."#{stage_table_name}" stage_update
        SET
          transition = 'KEEP',
          id = target.id
        FROM "#{target_schema}"."#{stage_table_name}" stage
        JOIN "#{target_schema}"."#{table_name}" target ON (
          target.external_id = stage.external_id
          AND target.external_source = '#{external_source}'
          AND target.deleted_at IS NULL
          AND
            (#{target_record_columns.join(', ')})
            IS NOT DISTINCT FROM
            (#{stage_record_columns.join(', ')})
        )
        WHERE stage_update.external_id = stage.external_id
      SQL
    end

    private

    def target_record_columns
      prefixed_columns(data_columns, 'target')
    end

    def stage_record_columns
      prefixed_columns(data_columns, 'stage')
    end

    def data_columns
      table_columns - ignored_columns
    end

    def table_columns
      @table_columns ||= database.column_names(target_schema, stage_table_name)
    end

    def ignored_columns
      importer_columns + [:id] + table_columns.select do |column_name|
        column_name.to_s.index(/^external_.+_id$/)
      end
    end

    def importer_columns
      IMPORTER_COLUMNS
    end

    def prefixed_columns(columns, prefix)
      columns.map { |column| %Q("#{prefix}"."#{column}") }
    end

  end
end
