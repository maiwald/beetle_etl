module BeetleETL
  class Reporter

    def initialize(report)
      @report = report
    end

    def log_summary
      BeetleETL.logger.info(summary)
    end

    private

    def summary
      "\n\n" +
      @report.map do |(table_name, steps)|
        total_duration = format_duration(sum_durations(steps))
        [
          table_name,
          seperator("="),
          step_rows(steps).join("\n"),
          seperator("-"),
          total_duration.rjust(line_width)
        ].join("\n")
      end.join("\n\n") + "\n"
    end

    def step_rows(steps)
      steps.map do |step_name, data|
        label = step_name.split(": ")[1] + ":"
        duration = format_duration(data[:finished_at] - data[:started_at])
        line = duration.rjust(line_width)
        line[2, label.length] = label
        line
      end
    end

    def format_duration(duration)
      Time.at(duration).utc.strftime("%H:%M:%S")
    end

    def sum_durations(steps)
      steps.inject(0) do |acc, (_step_name, data)|
        acc + (data[:finished_at] - data[:started_at])
      end
    end

    def line_width
      #   2 spaces
      # + 1 colon
      # + 1 space
      # + 8 duration
      12 + longest_step_name_length
    end

    def longest_step_name_length
      @report.keys.max_by(&:length).length - 1
    end

    def seperator(character)
      character * line_width
    end

  end
end
