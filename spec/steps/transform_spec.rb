require 'spec_helper'

module Beetle
  describe Transform do

    describe '#run' do
      it 'runs a query in the database' do
        database = double(:database)
        Beetle.configure { |config| config.database = database }

        query = double(:query)
        expect(database).to receive(:run).with(query)

        Transform.new(:table_name, query).run
      end
    end
  end
end
