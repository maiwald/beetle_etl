require_relative './abstract_step_runner'

module BeetleETL
  class SequentialStepRunner < AbstractStepRunner

    def run
      @steps.reduce({}) do |results, step|
        add_result!(results, run_step(step))
      end
    end

  end
end
