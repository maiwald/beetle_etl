module Beetle
  class TableDiff

    def initialize(transformation)
      @transformation = transformation
    end

    def transition_create
      database[:"stage__#{table_name}___new_record"]
        .where(
          new_record__import_run_id: run_id,
        )
        .where(Sequel.~(database[:"#{table_name}___old_record"].where(
            old_record__external_id: :new_record__external_id,
            old_record__external_source: :new_record__external_source,
          )
          .exists))
        .update(transition: 'CREATE')
    end

    private

    def run_id
      Beetle.state.run_id
    end

    def database
      Beetle.database
    end

    def table_name
      @transformation.table_name
    end

  end
end
