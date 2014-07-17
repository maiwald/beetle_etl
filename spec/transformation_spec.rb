require 'spec_helper'

module Beetle
  describe Transformation do

    describe '#table_name' do
      it 'returns the given table name' do
        transformation = Transformation.new(:table, Proc.new {})
        expect(transformation.table_name).to eql(:table)
      end
    end

    describe '#references' do
      it 'returns the list of foreign tables and their foreign key column' do
        setup = Proc.new do
          references :foreign_table, on: :foreign_table_id
        end
        transformation = Transformation.new(:table, setup)

        expect(transformation.references).to eql({
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

        expect(transformation.dependencies).to eql([:foreign_table, :another_foreign_table])
      end
    end

    describe '#query' do
      it 'returns the query interpolating external_source and run_id methods' do

        setup = Proc.new do
          query "SELECT #{run_id}, '#{external_source}' FROM some_table"
        end
        transformation = Transformation.new(:table, setup)

        expect(transformation.query).to eql(
          "SELECT 1, 'my_source' FROM some_table"
        )
      end
    end

  end
end
