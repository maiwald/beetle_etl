require 'active_support/core_ext/hash/deep_merge'

module BeetleETL
  class Import

    def initialize(config)
      @config = config
    end

    def run
      setup
      import
    ensure
      cleanup
    end

    def setup
      transformations.each do |t|
        CreateStage.new(@config, t.table_name, t.relations, t.column_names).run
      end
    end

    def import
      data_report = AsyncStepRunner.new(@config, data_steps).run
      load_report = @config.database.transaction do
        AsyncStepRunner.new(@config, load_steps).run
      end

      data_report.deep_merge load_report
    end

    def cleanup
      transformations.each do |t|
        DropStage.new(@config, t.table_name).run
      end
    end

    private

    def data_steps
      transformations.flat_map do |t|
        [
          Transform.new(@config, t.table_name, t.dependencies, t.query),
          MapRelations.new(@config, t.table_name, t.relations),
          TableDiff.new(@config, t.table_name),
          AssignIds.new(@config, t.table_name),
        ]
      end
    end

    def load_steps
      transformations.map do |t|
        Load.new(@config, t.table_name, t.relations)
      end
    end

    def transformations
      @transformations ||= TransformationLoader.new(@config).load
    end

  end
end
