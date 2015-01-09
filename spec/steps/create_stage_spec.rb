require 'spec_helper'

module BeetleETL
  describe CreateStage do

    describe '#dependencies' do
      it 'has no dependencies' do
        subject = CreateStage.new(:example_table, double(:dependencies), double(:columns))
        expect(subject.dependencies).to eql(Set.new)
      end
    end

    describe '#run' do
      before do
        BeetleETL.configure do |config|
          config.stage_schema = 'stage'
          config.database = test_database
        end

        test_database.execute <<-SQL
          CREATE TABLE example_table (
            id INTEGER,
            external_id character varying(255),
            external_source character varying(255),

            some_string character varying(200),
            some_integer integer,
            some_float double precision,

            PRIMARY KEY (id)
          )
        SQL
      end

      subject do
        relations = {
          dependee_a_id: :dependee_a,
          dependee_b_id: :dependee_b,
        }
        columns = %i(some_string some_integer some_float)
        CreateStage.new(:example_table, relations, columns)
      end

      it 'creates a stage table table with all payload columns' do
        subject.run

        columns = Hash[test_database.schema(:stage__example_table)]

        expect(columns.keys).to match_array %i(
          id
          external_id
          some_string
          some_integer
          some_float
        )

        expect(columns[:id][:db_type]).to eq('integer')
        expect(columns[:external_id][:db_type]).to eq('character varying(255)')

        expect(columns[:some_string][:db_type]).to eq('character varying(200)')
        expect(columns[:some_integer][:db_type]).to eq('integer')
        expect(columns[:some_float][:db_type]).to eq('double precision')
      end
    end

  end
end
