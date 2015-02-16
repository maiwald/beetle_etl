require 'spec_helper'

module BeetleETL
  describe Transformation do

    describe '#table_name' do
      it 'returns the given table name' do
        transformation = Transformation.new(:table, Proc.new {})
        expect(transformation.table_name).to eql(:table)
      end
    end

    describe 'columns' do
      it 'returns a list of payload column name symbols' do
        setup = Proc.new do
          columns :payload_1, 'payload_2'
        end
        transformation = Transformation.new(:table, setup)

        expect(transformation.column_names).to match_array([
          :payload_1, :payload_2
        ])
      end
    end

    describe '#relations' do
      it 'returns the list of foreign tables and their foreign key column' do
        setup = Proc.new do
          references :foreign_table, on: :foreign_table_id
        end
        transformation = Transformation.new(:table, setup)

        expect(transformation.relations).to eql({
          foreign_table_id: :foreign_table
        })
      end
    end

    describe '#dependencies' do
      it 'returns the depending tables' do
        setup = Proc.new do
          references :foreign_table, on: :foreign_table_id
          references :another_foreign_table, on: :another_foreign_table_id
        end
        transformation = Transformation.new(:table, setup)

        expect(transformation.dependencies).to eql(Set.new([:foreign_table, :another_foreign_table]))
      end
    end

    describe '#query' do
      it 'returns the query interpolating methods in scope' do
        setup = Proc.new do
          def foo; "foo_string"; end
          query "SELECT '#{foo}' FROM some_table"
        end
        transformation = Transformation.new(:table, setup)

        expect(transformation.query).to eql(
          "SELECT 'foo_string' FROM some_table"
        )
      end

      it 'concatenates multiple queries' do
        setup = Proc.new do
          query "SOME QUERY"
          query "ANOTHER QUERY"
        end
        transformation = Transformation.new(:table, setup)

        expect(transformation.query).to eql(
          "SOME QUERY;ANOTHER QUERY"
        )
      end
    end

  end
end
