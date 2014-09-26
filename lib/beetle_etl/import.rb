module BeetleETL
  module Import

    extend self

    def run
      TaskRunner.run(data_steps)
      BeetleETL.database.transaction do
        load_steps.each(&:run)
      end
    end

    private

    def data_steps
      transformations.map do |t|
        [
          Transform.new(t.table_name, t.dependencies, t.query),
          MapRelations.new(t.table_name, t.relations),
          TableDiff.new(t.table_name),
          AssignIds.new(t.table_name),
        ]
      end.flatten
    end

    def load_steps
      transformations.map do |t|
        Load.new(t.table_name)
      end
    end

    def transformations
      @transformations ||= TransformationLoader.load
    end

  end
end
