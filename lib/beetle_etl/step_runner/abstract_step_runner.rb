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

      step.started_at = Time.now
      step.run
      step.finished_at = Time.now

      duration = Time.at(step.finished_at - step.started_at).utc.strftime("%H:%M:%S")
      @config.logger.info("finished #{step.name} in #{duration}")

      step
    rescue => e
      @config.logger.fatal(e.message)
      raise e
    end

  end
end
