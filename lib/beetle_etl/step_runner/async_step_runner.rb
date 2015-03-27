module BeetleETL
  class AsyncStepRunner

    def initialize(steps)
      @dependency_resolver = DependencyResolver.new(steps)
      @steps = steps

      @queue = Queue.new
      @completed = Set.new
      @running = Set.new
    end

    def run
      results = {}

      until all_steps_complete?
        runnables.each do |step|
          run_step_async(step)
          mark_step_running(step.name)
        end

        table_name, step_name, step_data = @queue.pop

        unless results.has_key?(table_name)
          results[table_name] = {}
        end

        results[table_name][step_name] = step_data
        mark_step_completed(step_name)
      end

      results
    end

    private

    attr_reader :running, :completed

    def run_step_async(step)
      Thread.new do
        begin
          BeetleETL.logger.info("started step #{step.name}")

          started_at = Time.now
          step.run
          finished_at = Time.now

          duration = Time.at(finished_at - started_at).utc.strftime("%H:%M:%S")
          BeetleETL.logger.info("finished #{step.name} in #{duration}")

          @queue.push [
            step.table_name,
            step.name,
            { started_at: started_at, finished_at: finished_at }
          ]

        rescue => e
          BeetleETL.logger.fatal(e.message)
          raise e
        end
      end
    end

    def mark_step_running(step_name)
      running.add(step_name)
    end

    def mark_step_completed(step_name)
      runnables.delete(step_name)
      completed.add(step_name)
    end

    def runnables
      resolvables = @dependency_resolver.resolvables(completed)
      resolvables.reject { |r| running.include? r.name }
    end

    def all_steps_complete?
      @steps.map(&:name).to_set == completed.to_set
    end

  end
end
