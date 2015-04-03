require 'sequel'
require 'yaml'
require 'rspec/expectations'

module SpecSupport
  module DatabaseHelpers

    module Test
      class Table
        def initialize dataset
          @dataset = dataset
        end

        def values(*data)
          columns = data[0]
          values = data[1..-1]
          @dataset.import(columns, values)
        end
      end
    end

    def test_database
      @database ||= begin
        config_path = File.expand_path('./database.yml', File.dirname(__FILE__))
        config = File.read(config_path)
        Sequel.connect(YAML.load(config))
      end
    end

    def insert_into(table_description)
      dataset = test_database[table_description]
      Test::Table.new(dataset)
    end

  end
end

RSpec::Matchers.define :have_values do |*rows|
  match do |table_description|
    dataset = test_database[table_description.to_sym]

    columns = rows[0].map(&:to_sym)
    values = rows[1..-1]

    begin
      expect{dataset.select(columns).all}.not_to raise_error
      expect(dataset.map(columns)).to match_array(values)
      true
    rescue RSpec::Expectations::ExpectationNotMetError => error
      @expectation_not_met_error = error
      false
    end
  end

  failure_message do |dataset|
    @expectation_not_met_error.message
  end
end
