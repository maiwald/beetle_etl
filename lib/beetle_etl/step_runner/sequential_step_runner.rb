require_relative './abstract_step_runner'

module BeetleETL
  class SequentialStepRunner < AbstractStepRunner

    def run
      @steps.map do |step|
        run_step(step)
      end
    end

  end
end
