require 'spec_helper'

describe BeetleETL do
  describe '#import' do

    it 'runs the import' do
      allow(BeetleETL).to receive(:state) { double(:state).as_null_object }
      expect(BeetleETL::Import).to receive(:run)
      BeetleETL.import
    end

    context 'handling state' do
      it 'starts the import and marks it as finished if no errors are thrown' do
        allow(BeetleETL::Import).to receive(:run)

        expect(BeetleETL.state).to receive(:start_import).ordered
        expect(BeetleETL.state).to receive(:mark_as_succeeded).ordered

        BeetleETL.import
      end

      it 'starts the import and marks it as failed if Import.run throws an error' do
        exception = Exception.new
        allow(BeetleETL::Import).to receive(:run).and_raise(exception)

        expect(BeetleETL.state).to receive(:start_import).ordered
        expect(BeetleETL.state).to receive(:mark_as_failed).ordered

        expect { BeetleETL.import }.to raise_exception(exception)
      end
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
