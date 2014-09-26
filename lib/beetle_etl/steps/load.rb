module BeetleETL
  class Load < Step

    IMPORTER_COLUMNS = %i[
      import_run_id
      external_source
      transition
    ]

    def run
      %w(create update delete undelete).each do |transition|
        public_send(:"load_#{transition}")
      end
    end

    def load_create
      just_now = now
      database[table_name].import(
        data_columns + [:external_source, :created_at, :updated_at],
        database[:"#{stage_schema}__#{table_name}"]
          .select(*data_columns)
          .where(
            import_run_id: run_id,
            transition: 'CREATE'
          )
          .select_more(external_source, just_now, just_now)
        )
    end

    def load_update
      updates = updatable_columns.reduce({updated_at: now}) do |acc, column|
        acc[column] = :"stage__#{column}"
        acc
      end

      database.from(
        :"#{table_name}___public",
        :"#{stage_schema}__#{table_name}___stage"
      )
        .where(
          stage__id: :public__id,
          stage__transition: 'UPDATE',
          stage__import_run_id: run_id,
        )
        .update(updates)
    end

    def load_delete
      just_now = now
      database.from(
          :"#{table_name}___public",
          :"#{stage_schema}__#{table_name}___stage"
        )
        .where(
          stage__id: :public__id,
          stage__transition: 'DELETE',
          stage__import_run_id: run_id,
        )
        .update(
          updated_at: just_now,
          deleted_at: just_now,
        )
    end

    def load_undelete
      updates = updatable_columns.reduce({updated_at: now, deleted_at: nil}) do |acc, column|
        acc[column] = :"stage__#{column}"
        acc
      end

      database.from(
        :"#{table_name}___public",
        :"#{stage_schema}__#{table_name}___stage"
      )
        .where(
          stage__id: :public__id,
          stage__transition: 'UNDELETE',
          stage__import_run_id: run_id,
        )
        .update(updates)
    end

    private

    def data_columns
      table_columns - ignored_columns
    end

    def table_columns
      @table_columns ||= database[:"#{stage_schema}__#{table_name}"].columns
    end

    def ignored_columns
      IMPORTER_COLUMNS + table_columns.select do |column_name|
        column_name.to_s.index(/^external_.+_id$/)
      end
    end

    def updatable_columns
      data_columns - [:id, :external_source, :external_id]
    end

    def now
      Time.now
    end

  end
end
