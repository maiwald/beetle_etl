require 'active_support/core_ext/hash/slice'

module BeetleETL
  class AbstractStepRunner

    def initialize(config, steps)
      @config = config
      @steps = steps
    end

    def run
      raise NotImplementedError
    end

    private

    def run_step(step)
      @config.logger.info("started step #{step.name}")

      started_at = Time.now
      step.run
      finished_at = Time.now

      duration = Time.at(finished_at - started_at).utc.strftime("%H:%M:%S")
      @config.logger.info("finished #{step.name} in #{duration}")

      {
        step_name: step.name,
        table_name: step.table_name,
        started_at: started_at,
        finished_at: finished_at
      }
    rescue => e
      @config.logger.fatal(e.message)
      raise e
    end

    def add_result!(results, step_data)
      table_name = step_data[:table_name]
      step_name = step_data[:step_name]

      results[table_name] ||= {}
      results[table_name][step_name] = step_data.slice(:started_at, :finished_at)
    end

  end
end
