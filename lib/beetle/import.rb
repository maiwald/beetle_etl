module Beetle
  module Import

    extend self

    def run
      transformations.each do |transformation|
        Beetle.database.run(transformation.query)
      end

      transformations.each do |t|
        MapRelations.new(t.table_name, t.relations).run
        TableDiff.new(t.table_name).run
        AssignIds.new(t.table_name).run
      end

      Beetle.database.transaction do
        transformations.each do |t|
          Load.new(t.table_name).run
        end
      end
    end

    private

    def transformations
      @transformations ||= begin
        t = TransformationLoader.load
        DependencyResolver.new(t).resolved
      end
    end

  end
end
