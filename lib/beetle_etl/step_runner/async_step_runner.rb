require_relative './abstract_step_runner'
require_relative './dependency_resolver'

module BeetleETL
  class AsyncStepRunner < AbstractStepRunner

    def initialize(config, steps)
      super(config, steps)

      @dependency_resolver = DependencyResolver.new(steps)

      @queue = Queue.new
      @completed = Set.new
      @started = Set.new
    end

    def run
      until all_steps_complete?
        runnables.each do |step|
          run_step_async(step)
          @started.add(step)
        end

        @completed.add(@queue.pop)
      end

      @completed
    end

    private

    def run_step_async(step)
      Thread.new do
        run_step(step)
        @queue.push step
      end.abort_on_exception = true
    end

    def runnables
      resolvables = @dependency_resolver.resolvables(@completed)
      resolvables.reject { |r| @started.include? r }
    end

    def all_steps_complete?
      @steps.to_set == @completed.to_set
    end

  end
end
