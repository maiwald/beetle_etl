require 'spec_helper'

describe BeetleETL do

  describe '#import' do
    it 'runs the import with reporting' do
      report = double(:report)
      reporter = double(:reporter, log_summary: nil)

      expect(BeetleETL::Import).to receive_message_chain(:new, :run).and_return report
      expect(BeetleETL::Reporter).to receive(:new).with(report).and_return reporter
      expect(BeetleETL.import).to eql(report)
    end
  end

  describe '#config' do
    it 'returns a configuration object' do
      expect(BeetleETL.config).to be_a(BeetleETL::Configuration)
    end
  end

  describe '#configure' do
    it 'allows the configuration to be changed' do
      expect(BeetleETL.config.external_source).to be_nil

      BeetleETL.configure { |config| config.external_source = 'foo' }

      expect(BeetleETL.config.external_source).to eql('foo')
    end
  end

  describe '#database' do
    let(:database) { double(:database) }

    it 'returns the Sequel Database object stored in the config' do
      BeetleETL.configure { |config| config.database = database }

      expect(BeetleETL.database).to eql(database)
    end

    it 'builds and caches a Sequel Database from config when no database is passed' do
      database_config = double(:database_config)
      BeetleETL.configure { |config| config.database_config = database_config }

      expect(Sequel).to receive(:connect).with(database_config).once { database }

      expect(BeetleETL.database).to eql(database)
      expect(BeetleETL.database).to eql(database)
    end
  end

end
