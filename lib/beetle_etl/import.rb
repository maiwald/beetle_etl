require 'active_support/core_ext/hash/deep_merge'

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

      @report.deep_merge SequentialStepRunner.new(@config, steps).run
    end

    def run_transform
      steps = @transformations.flat_map { |t|
        [
          Transform.new(@config, t.table_name, t.dependencies, t.query),
          MapRelations.new(@config, t.table_name, t.relations),
          TableDiff.new(@config, t.table_name)
        ]
      }

      @report.deep_merge AsyncStepRunner.new(@config, steps).run
    end

    def run_load
      steps = @transformations.map { |t|
        Load.new(@config, t.table_name, t.relations)
      }

      result = @config.database.transaction do
        SequentialStepRunner.new(@config, steps).run
      end

      @report.deep_merge result
    end

    def run_cleanup
      steps = @transformations.map { |t|
        DropStage.new(@config, t.table_name)
      }

      @report.deep_merge SequentialStepRunner.new(@config, steps).run
    end

  end
end
