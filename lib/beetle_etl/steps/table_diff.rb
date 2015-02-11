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
      %w(create keep update delete undelete).map do |transition|
        public_send(:"transition_#{transition}")
      end
    end

    def transition_create
      database.execute <<-SQL
        UPDATE #{stage_table_name_sql} stage
        SET transition = 'CREATE'
        WHERE NOT EXISTS (
          SELECT 1
          FROM #{public_table_name} public
          WHERE public.external_id = stage.external_id
          AND public.external_source = '#{external_source}'
        )
      SQL
    end

    def transition_keep
      database.execute <<-SQL
        UPDATE #{stage_table_name_sql} stage
        SET transition = 'KEEP'
        WHERE EXISTS (
          SELECT 1
          FROM #{public_table_name} public
          WHERE public.external_id = stage.external_id
          AND public.external_source = '#{external_source}'
          AND public.deleted_at IS NULL
          AND
            (#{public_record_columns.join(', ')})
            IS NOT DISTINCT FROM
            (#{stage_record_columns.join(', ')})
        )
      SQL
    end

    def transition_update
      database.execute <<-SQL
        UPDATE #{stage_table_name_sql} stage
        SET transition = 'UPDATE'
        WHERE EXISTS (
          SELECT 1
          FROM #{public_table_name} public
          WHERE public.external_id = stage.external_id
          AND public.external_source = '#{external_source}'
          AND public.deleted_at IS NULL
          AND
            (#{public_record_columns.join(', ')})
            IS DISTINCT FROM
            (#{stage_record_columns.join(', ')})
        )
      SQL
    end

    def transition_delete
      database.execute <<-SQL
        INSERT INTO #{stage_table_name_sql}
          (external_id, transition)
        SELECT
          public.external_id,
          'DELETE'
        FROM #{public_table_name_sql} public
        LEFT OUTER JOIN (
          SELECT *
          FROM #{stage_table_name_sql}
          ) stage
          ON (stage.external_id = public.external_id)
        WHERE stage.external_id IS NULL
        AND public.external_source = '#{external_source}'
        AND public.deleted_at IS NULL
      SQL
    end

    def transition_undelete
      database.execute <<-SQL
        UPDATE #{stage_table_name_sql} stage
        SET transition = 'UNDELETE'
        WHERE EXISTS (
          SELECT 1
          FROM #{public_table_name_sql} public
          WHERE public.external_id = stage.external_id
          AND public.external_source = '#{external_source}'
          AND public.deleted_at IS NOT NULL
        )
      SQL
    end

    private

    def public_record_columns
      prefixed_columns(data_columns, 'public')
    end

    def stage_record_columns
      prefixed_columns(data_columns, 'stage')
    end

    def data_columns
      table_columns - ignored_columns
    end

    def table_columns
      @table_columns ||= database[stage_table_name.to_sym].columns
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
