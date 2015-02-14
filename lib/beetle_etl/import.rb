module BeetleETL
  class Import

    def run
      TaskRunner.new(data_steps).run
      BeetleETL.database.transaction do
        TaskRunner.new(load_steps).run
      end
    rescue => e
      raise e
    ensure
      TaskRunner.new(cleanup_steps).run
    end

    private

    def data_steps
      transformations.flat_map do |t|
        [
          CreateStage.new(t.table_name, t.relations, t.column_names),
          Transform.new(t.table_name, t.dependencies, t.query),
          MapRelations.new(t.table_name, t.relations),
          TableDiff.new(t.table_name),
          AssignIds.new(t.table_name),
        ]
      end
    end

    def load_steps
      transformations.map do |t|
        Load.new(t.table_name, t.relations)
      end
    end

    def cleanup_steps
      transformations.map { |t| DropStage.new(t.table_name) }
    end

    def transformations
      @transformations ||= TransformationLoader.load
    end

  end
end
