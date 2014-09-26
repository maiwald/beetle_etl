module BeetleETL
  class TableDiff < Step

    IMPORTER_COLUMNS = %i[
      import_run_id
      external_id
      transition
    ]

    def dependencies
      [MapRelations.step_name(table_name)].to_set
    end

    def run
      %w(create keep update delete undelete).each do |transition|
        public_send(:"transition_#{transition}")
      end
    end

    def transition_create
      stage_table.where(
        stage__import_run_id: run_id,
      )
      .where(Sequel.~(public_table.where(
          public__external_id: :stage__external_id,
          public__external_source: external_source,
        )
        .exists))
      .update(transition: 'CREATE')
    end

    def transition_keep
      stage_table.where(
        stage__import_run_id: run_id,
      )
      .where(
        public_table.where(
          public__external_id: :stage__external_id,
          public__external_source: external_source,
          public__deleted_at: nil,
        )
        .where(
          ':public_columns IS NOT DISTINCT FROM :stage_columns',
          public_columns: public_record_columns,
          stage_columns: stage_record_columns,
        )
        .exists)
      .update(transition: 'KEEP')
    end

    def transition_update
      stage_table.where(
        stage__import_run_id: run_id,
      )
      .where(
        public_table.where(
          public__external_id: :stage__external_id,
          public__external_source: external_source,
          public__deleted_at: nil,
        )
        .where(
          ':public_columns IS DISTINCT FROM :stage_columns',
          public_columns: public_record_columns,
          stage_columns: stage_record_columns,
        )
        .exists)
      .update(transition: 'UPDATE')
    end

    def transition_delete
      deleted_dataset = database.from(
        :"#{stage_schema}__#{table_name}___stage",
      ).right_join(
        :"#{table_name}___public",
        public__external_id: :stage__external_id,
        public__external_source: external_source,
      ).where(
        stage__external_id: nil,
        public__deleted_at: nil
      )

      database[:"#{stage_schema}__#{table_name}"]
        .import(
          [
            :import_run_id,
            :external_id,
            :transition
          ],
          deleted_dataset
            .select(
              run_id,
              :public__external_id,
              'DELETE'
            )
        )
    end

    def transition_undelete
      stage_table.where(
        stage__import_run_id: run_id,
      )
      .where(
        public_table.where(
          public__external_id: :stage__external_id,
          public__external_source: external_source,
        )
        .exclude(
          public__deleted_at: nil
        )
        .exists)
      .update(transition: 'UNDELETE')
    end

    private

    def stage_table
      @stage_table ||= database[:"#{stage_schema}__#{table_name}___stage"]
    end

    def public_table
      @public_table ||= database[:"#{table_name}___public"]
    end

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
      @table_columns ||= database[:"#{stage_schema}__#{table_name}"].columns
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
      columns.map { |column| "#{prefix}__#{column}".to_sym }
    end

  end
end
