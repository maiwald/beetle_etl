require 'spec_helper'

module Beetle
  describe Import do

    describe '#populate_stage_tables' do
      it 'runs every transformation‘s query' do
        database = double(:database)
        Beetle.configure { |config| config.database = database }

        t1 = double(:transformation_1, query: double(:query_1))
        t2 = double(:transformation_2, query: double(:query_2))

        expect(database).to receive(:run).with(t1.query).ordered
        expect(database).to receive(:run).with(t2.query).ordered

        subject.send(:populate_stage_tables, [t1, t2])
      end
    end
  end
end

