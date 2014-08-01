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

    Item = Struct.new(:name, :dependencies)

    let(:a) { Item.new(:a, Set.new) }
    let(:b) { Item.new(:b, Set.new([:a])) }
    let(:c) { Item.new(:c, Set.new([:a])) }
    let(:d) { Item.new(:d, Set.new([:a, :c])) }
    let(:e) { Item.new(:e, Set.new([:c, :d])) }
    let(:f) { Item.new(:f, Set.new([:c, :d])) }

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
      let(:cyclic) { Item.new(:a, Set.new([:b])) }

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
