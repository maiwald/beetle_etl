module BeetleETL
  class Import

    def initialize(config)
      @config = config
      @report = {}

      @transformations ||= TransformationLoader.new(@config).load
    end

    def run
      begin
        run_setup
        run_transform
        run_load
      ensure
        run_cleanup
      end

      @report
    end

    def run_setup
      steps = @transformations.map { |t|
        CreateStage.new(@config, t.table_name, t.relations, t.column_names)
      }

      merge_report! StepRunner.new(@config, steps).run
    end

    def run_transform
      steps = @transformations.flat_map { |t|
        [
          Transform.new(@config, t.table_name, t.dependencies, t.query),
          MapRelations.new(@config, t.table_name, t.relations),
          TableDiff.new(@config, t.table_name)
        ]
      }

      merge_report! AsyncStepRunner.new(@config, steps).run
    end

    def run_load
      steps = @transformations.map { |t|
        Load.new(@config, t.table_name, t.relations)
      }

      result = @config.database.transaction do
        StepRunner.new(@config, steps).run
      end

      merge_report! result
    end

    def run_cleanup
      steps = @transformations.map { |t|
        DropStage.new(@config, t.table_name)
      }

      merge_report! StepRunner.new(@config, steps).run
    end

    def merge_report!(new_report)
      @report.merge!(new_report) { |key, oldval, newval| oldval.merge(newval) }
    end

  end
end
