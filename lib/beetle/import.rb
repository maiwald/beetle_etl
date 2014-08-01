module Beetle
  module Import

    extend self

    def run
      data_steps.each(&:run)

      Beetle.database.transaction do
        load_steps.each(&:run)
      end
    end

    private

    def data_steps
      transformations.map do |t|
        [
          Transform.new(t.table_name, t.query),
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
      @transformations ||= begin
        t = TransformationLoader.load
        DependencyResolver.new(t).resolved
      end
    end

  end
end
