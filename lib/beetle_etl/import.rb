require 'active_support/core_ext/hash/deep_merge'

module BeetleETL
  class Import

    def initialize(config)
      @config = config
      @transformations ||= TransformationLoader.new(@config).load
    end

    def run
      report = []

      begin
        report.push run_setup
        report.push run_transform
        report.push run_load
      ensure
        report.push run_cleanup
      end

      report
    end

    def run_setup
      steps = @transformations.map { |t|
        CreateStage.new(@config, t.table_name, t.relations, t.column_names)
      }

      SequentialStepRunner.new(@config, steps).run
    end

    def run_transform
      steps = @transformations.flat_map { |t|
        [
          Transform.new(@config, t.table_name, t.dependencies, t.query),
          MapRelations.new(@config, t.table_name, t.relations),
          TableDiff.new(@config, t.table_name),
          AssignIds.new(@config, t.table_name),
        ]
      }

      AsyncStepRunner.new(@config, steps).run
    end

    def run_load
      steps = @transformations.map { |t|
        Load.new(@config, t.table_name, t.relations)
      }

      @config.database.transaction do
        SequentialStepRunner.new(@config, steps).run
      end

    end

    def run_cleanup
      steps = @transformations.map { |t|
        DropStage.new(@config, t.table_name)
      }

      SequentialStepRunner.new(@config, steps).run
    end

  end
end
