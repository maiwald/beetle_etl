module BeetleETL
  class TaskRunner

    def initialize(tasks)
      @dependency_resolver = DependencyResolver.new(tasks)
      @tasks = tasks

      @queue = Queue.new
      @completed = Set.new
      @running = Set.new
    end

    def run
      results = {}

      until all_tasks_complete?
        runnables.each do |task|
          run_task_async(task)
          mark_task_running(task.name)
        end

        task_name, task_data = @queue.pop
        results[task_name] = task_data
        mark_task_completed(task_name)
      end

      results
    end

    private

    attr_reader :running, :completed

    def run_task_async(task)
      Thread.new do
        begin
          BeetleETL.logger.info("started task #{task.name}")

          started_at = Time.now
          task.run
          finished_at = Time.now

          duration = Time.at(finished_at - started_at).utc.strftime("%H:%M:%S")
          BeetleETL.logger.info("finished #{task.name} in #{duration}")

          @queue.push [task.name, {
            started_at: started_at,
            finished_at: finished_at,
          }]

        rescue => e
          BeetleETL.logger.fatal(e.message)
          raise e
        end
      end
    end

    def mark_task_running(task_name)
      running.add(task_name)
    end

    def mark_task_completed(task_name)
      runnables.delete(task_name)
      completed.add(task_name)
    end

    def runnables
      resolvables = @dependency_resolver.resolvables(completed)
      resolvables.reject { |r| running.include? r.name }
    end

    def all_tasks_complete?
      @tasks.map(&:name).to_set == completed.to_set
    end

  end
end
