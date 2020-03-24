require_relative './dependency_resolver'

module BeetleETL
  class StepRunner

    def initialize(config, steps)
      @config = config
      @steps = steps
      @dependency_resolver = DependencyResolver.new(steps)
      @completed = Set.new
    end

    def run
      results = {}

      until all_steps_complete?
        runnables.each do |step|
          add_result!(results, run_step(step))
          @completed.add(step.name)
        end
      end

      results
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

    def runnables
      @dependency_resolver.resolvables(@completed)
    end

    def add_result!(results, step_data)
      table_name = step_data[:table_name]
      step_name = step_data[:step_name]

      results[table_name] ||= {}
      results[table_name][step_name] = {
        started_at: step_data[:started_at],
        finished_at: step_data[:finished_at]
      }
    end

    def all_steps_complete?
      @steps.map(&:name).to_set == @completed.to_set
    end

  end
end
