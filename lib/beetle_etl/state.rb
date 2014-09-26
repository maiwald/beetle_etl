module BeetleETL

  ImportAleadyRunning = Class.new(StandardError)
  ImportSchemaNotFound = Class.new(StandardError)
  ImportNotRunning = Class.new(StandardError)

  class State

    def start_import
      raise ImportAleadyRunning if import_already_running?

      @run_id = import_runs_dataset.insert(
        state: 'RUNNING',
        started_at: now
      )
    end

    def mark_as_succeeded
      mark_as('SUCCEEDED')
    end

    def mark_as_failed
      mark_as('FAILED')
    end

    def run_id
      raise ImportNotRunning if @run_id.nil?
      @run_id
    end

    def last_run_id
      last_import = import_runs_dataset.
        select(:id).
        where(state: 'SUCCEEDED').
        order(Sequel.desc(:id)).
        first

      last_import.nil? ? nil : last_import[:id]
    end

  private

    def import_runs_table
      "#{BeetleETL.config.stage_schema}__import_runs".to_sym
    end

    def import_already_running?
      import_runs_dataset.where(state: 'RUNNING').count > 0
    end

    def now
      Time.now
    end

    def mark_as(state)
      import_runs_dataset.filter(id: run_id).update(
        state: state,
        finished_at: now
      )
    end

    def import_runs_dataset
      BeetleETL.database[import_runs_table]
    end

  end
end
