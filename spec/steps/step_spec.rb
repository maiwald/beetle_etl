require 'spec_helper'

module BeetleETL
  describe Step do

    subject { Step.new(:example_table) }
    FooStep = Class.new(Step)

    describe '.step_name' do
      it 'returns the steps name' do
        expect(Step.step_name(:example_table)).to eql('example_table: Step')
      end

      it 'returns the step name of inheriting steps' do
        expect(FooStep.step_name(:foo_table)).to eql('foo_table: FooStep')
      end
    end

    describe '#name' do
      it 'returns the steps name' do
        expect(Step.new(:example_table).name).to eql('example_table: Step')
      end

      it 'returns the step name of inheriting steps' do
        expect(FooStep.new(:foo_table).name).to eql('foo_table: FooStep')
      end
    end

    describe '#dependencies' do
      it 'raises an exception' do
        expect { subject.dependencies }.to raise_error(DependenciesNotDefinedError)
      end

    end

  end
end
