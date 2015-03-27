require 'spec_helper'
require 'unindent'

module BeetleETL
  describe Reporter do

    let(:report) do
      {
        organisations: {
          "organisations: Transform" => {
            :started_at  => Time.new(2015, 03, 14, 16, 0),
            :finished_at => Time.new(2015, 03, 14, 16, 10)
          },
          "organisations: MapRelations" => {
            :started_at  => Time.new(2015, 03, 14, 17, 0),
            :finished_at => Time.new(2015, 03, 14, 17, 10)
          },
          "organisations: Load" => {
            :started_at  => Time.new(2015, 03, 14, 18, 0),
            :finished_at => Time.new(2015, 03, 14, 18, 10)
          },
        },
        departments: {
          "departments: Transform" => {
            :started_at  => Time.new(2015, 03, 14, 16, 0),
            :finished_at => Time.new(2015, 03, 14, 16, 12)
          },
          "departments: MapRelations" => {
            :started_at  => Time.new(2015, 03, 14, 17, 2),
            :finished_at => Time.new(2015, 03, 14, 17, 10)
          },
          "departments: Load" => {
            :started_at  => Time.new(2015, 03, 14, 18, 10),
            :finished_at => Time.new(2015, 03, 14, 19, 21, 39)
          },
        }
      }
    end

    it "loggs a summary of all step times by table name" do
      expect(BeetleETL.logger).to receive(:info).with <<-LOG.unindent


        organisations
        ========================
          Transform:    00:10:00
          MapRelations: 00:10:00
          Load:         00:10:00
        ------------------------
                        00:30:00

        departments
        ========================
          Transform:    00:12:00
          MapRelations: 00:08:00
          Load:         01:11:39
        ------------------------
                        01:31:39
      LOG

      Reporter.new(report).log_summary
    end

  end
end
