require 'spec_helper'

module Beetle
  describe DependencyResolver do

    # test dependencies
    #
    #     A
    #   / | \
    #  B  |  C
    #  |  \ /|
    #  |   D |
    #   \ / \|
    #    E   F

    TransformationDouble = Struct.new(:table_name, :dependencies)

    let(:a) { TransformationDouble.new(:a, Set.new) }
    let(:b) { TransformationDouble.new(:b, Set.new([:a])) }
    let(:c) { TransformationDouble.new(:c, Set.new([:a])) }
    let(:d) { TransformationDouble.new(:d, Set.new([:a, :c])) }
    let(:e) { TransformationDouble.new(:e, Set.new([:c, :d])) }
    let(:f) { TransformationDouble.new(:f, Set.new([:c, :d])) }

    describe '#resolved' do
      it 'returns an empty array if given an empty array' do
        expect(DependencyResolver.new([]).resolved).to eql([])
      end

      it 'orderes transformations by their dependencies' do
        result = DependencyResolver.new([b, e, c, f, a, d]).resolved
        expect(result).to eql([a, b, c, d, e, f])
      end
    end

    describe '#resolved_in_tiers' do
      it 'returns arrays of items that can run un parallel' do
        result = DependencyResolver.new([b, e, c, f, a, d]).resolved_in_tiers
        expect(result).to eql([[a], [b, c], [d], [e, f]])
      end
    end

    context 'exceptional states' do
      let(:cyclic) { TransformationDouble.new(:a, Set.new([:b])) }

      it 'detects cyclic dependencies' do
        expect { DependencyResolver.new([cyclic, b]) }.to \
          raise_error(Beetle::UnsatisfiableDependenciesError)
      end

      it 'detects unsatisfiable dependencies' do
        expect { DependencyResolver.new([b]) }.to \
          raise_error(Beetle::UnsatisfiableDependenciesError)
      end
    end

  end
end
