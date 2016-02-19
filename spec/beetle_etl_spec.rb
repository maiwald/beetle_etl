require 'spec_helper'

describe BeetleETL do

  describe '#import' do
    it 'runs the import with reporting' do
      config = double(:config, disconnect_database: nil)
      runner = double(:runner)
      report = double(:report)
      reporter = double(:reporter, log_summary: nil)

      expect(BeetleETL::Import).to receive(:new).with(config).and_return runner
      expect(runner).to receive(:run).and_return report
      expect(BeetleETL::Reporter).to receive(:new).with(config, report).and_return reporter

      expect(BeetleETL.import(config)).to eql(report)
    end
  end

end
