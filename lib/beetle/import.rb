module Beetle
  module Import

    extend self

    def run
      populate_stage_tables(transformations)
    end

    private

    def populate_stage_tables(transformations)
      transformations.each do |transformation|
        Beetle.database.run(transformation.query)
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
