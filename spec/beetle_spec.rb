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

      Beetle.configure do |config|
        config.external_source = 'foo'
      end

      expect(Beetle.config.external_source).to eql('foo')
    end
  end
end
