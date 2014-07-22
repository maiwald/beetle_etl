require 'spec_helper'

describe Beetle do
  describe '#import' do

    it 'runs the import' do
      allow(Beetle).to receive(:state) { double(:state).as_null_object }
      expect(Beetle::Import).to receive(:run)
      Beetle.import
    end

    context 'handling state' do
      it 'starts the import and marks it as finished if no errors are thrown' do
        allow(Beetle::Import).to receive(:run)

        expect(Beetle.state).to receive(:start_import).ordered
        expect(Beetle.state).to receive(:mark_as_succeeded).ordered

        Beetle.import
      end

      it 'starts the import and marks it as failed if Import.run throws an error' do
        exception = Exception.new
        allow(Beetle::Import).to receive(:run).and_raise(exception)

        expect(Beetle.state).to receive(:start_import).ordered
        expect(Beetle.state).to receive(:mark_as_failed).ordered

        expect { Beetle.import }.to raise_exception(exception)
      end
    end
  end

  describe '#config' do
    it 'returns a configuration object' do
      expect(Beetle.config).to be_a(Beetle::Configuration)
    end
  end

  describe '#configure' do
    it 'allows the configuration to be changed' do
      expect(Beetle.config.external_source).to be_nil

      Beetle.configure { |config| config.external_source = 'foo' }

      expect(Beetle.config.external_source).to eql('foo')
    end
  end

  describe '#database' do
    let(:database) { double(:database) }

    it 'returns the Sequel Database object stored in the config' do
      Beetle.configure { |config| config.database = database }

      expect(Beetle.database).to eql(database)
    end

    it 'builds and caches a Sequel Database from config when no database is passed' do
      database_config = double(:database_config)
      Beetle.configure { |config| config.database_config = database_config }

      expect(Sequel).to receive(:connect).with(database_config).once { database }

      expect(Beetle.database).to eql(database)
      expect(Beetle.database).to eql(database)
    end

  end
end
