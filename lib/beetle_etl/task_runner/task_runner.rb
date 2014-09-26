require 'celluloid/autostart'

module BeetleETL
  class TaskRunner

    include Celluloid

    def initialize(runnables)
      @runnables = runnables
      @completed = Set.new
      @running = Set.new
      @dependency_resolver = DependencyResolver.new(runnables)

      run_next
    end

    def completed(runnable_name)
      @running.delete(runnable_name)
      @completed << runnable_name

      run_next
    end

    def run_next
      if all_run?
        terminate
      else
        resolvables.each do |runnable|
          unless @running.include?(runnable.name)
            Task.new(Actor.current, runnable).async.run_task
            @running << runnable.name
          end
        end
      end
    end

    private

    def resolvables
      @dependency_resolver.resolvables(@completed)
    end

    def all_run?
      @completed == @runnables.map(&:name).to_set
    end

    class Task

      include Celluloid

      def initialize(runner, task)
        @runner = runner
        @task = task
      end

      def run_task
        @task.run
        @runner.async.completed(@task.name)
        terminate
      end
    end

  end
end
