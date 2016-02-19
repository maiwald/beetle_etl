require 'spec_helper'

module BeetleETL
  describe DSL do

    let(:config) do
      Configuration.new.tap do |c|
        c.external_source = "bar"
      end
    end

    subject { DSL.new(config, :foo_table) }

    describe '#stage_table' do
      it 'returns the current stage table name' do
        expect(subject.stage_table).to eql(
          BeetleETL::Naming.stage_table_name_sql("bar", :foo_table)
        )
      end

      it 'returns the stage table name for the given table' do
        expect(subject.stage_table(:bar_table)).to eql(
          BeetleETL::Naming.stage_table_name_sql("bar", :bar_table)
        )
      end
    end

    describe '#combined_key' do
      it 'returns an SQL string for combined external ids' do
        expect(subject.combined_key('foo', 'bar')).to eql(
          %q('[' || foo || ',' || bar || ']')
        )
      end

      it 'works with multiple arguments' do
        expect(subject.combined_key('foo', 'bar', 'baz')).to eql(
          %q('[' || foo || ',' || bar || ',' || baz || ']')
        )
      end
    end

  end
end
