require 'beetle_etl/version'

require 'sequel'
require 'logger'

module BeetleETL

  require 'beetle_etl/adapters/sequel_adapter'
  require 'beetle_etl/configuration'

  require 'beetle_etl/dsl/dsl'
  require 'beetle_etl/dsl/transformation'
  require 'beetle_etl/dsl/transformation_loader'

  require 'beetle_etl/naming'

  require 'beetle_etl/steps/step'
  require 'beetle_etl/steps/create_stage'
  require 'beetle_etl/steps/transform'
  require 'beetle_etl/steps/map_relations'
  require 'beetle_etl/steps/table_diff'
  require 'beetle_etl/steps/assign_ids'
  require 'beetle_etl/steps/load'
  require 'beetle_etl/steps/drop_stage'

  require 'beetle_etl/step_runner/sequential_step_runner'
  require 'beetle_etl/step_runner/async_step_runner'

  require 'beetle_etl/import'
  require 'beetle_etl/reporter'

  class << self

    def import(config = Configuration.new)
      yield config if block_given?

      begin
        report = Import.new(config).run
        Reporter.new(config, report).log_summary
        report
      ensure
        config.disconnect_database
      end
    end

  end
end
