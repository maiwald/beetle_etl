module BeetleETL
  module Import

    extend self

    def run
      TaskRunner.new(data_steps).run
      BeetleETL.database.transaction do
        TaskRunner.new(load_steps).run
      end
    end

    private

    def data_steps
      transformations.flat_map do |t|
        [
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

    def transformations
      @transformations ||= TransformationLoader.load
    end

  end
end
