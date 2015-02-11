require 'spec_helper'

module BeetleETL
  describe DSL do

    subject { DSL.new(:foo_table) }

    describe '#stage_table' do
      it 'returns the stage table name including the schema defined in the config' do
        expect(subject.stage_table).to eql(BeetleETL::Naming.stage_table_name_sql(:foo_table))
      end
    end

    describe '#external_source' do
      it 'returns the external source‘s identifier' do
        expect(subject.external_source).to eql('source')
      end
    end

    describe '#combined_key' do
      it 'returns an SQL string for combined external ids' do
        expect(subject.combined_key('foo', 'bar')).to eql(
          %q('[' || foo || '|' || bar || ']')
        )
      end

      it 'works with multiple arguments' do
        expect(subject.combined_key('foo', 'bar', 'baz')).to eql(
          %q('[' || foo || '|' || bar || '|' || baz || ']')
        )
      end
    end

  end
end
