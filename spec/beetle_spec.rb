require 'spec_helper'

describe Beetle do
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
