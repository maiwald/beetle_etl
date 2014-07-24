module Beetle
  module CommonHelpers

    def run_id
      Beetle.state.run_id
    end

    def stage_schema
      Beetle.config.stage_schema
    end

    def external_source
      Beetle.config.external_source
    end

    def database
      Beetle.database
    end

  end
end
