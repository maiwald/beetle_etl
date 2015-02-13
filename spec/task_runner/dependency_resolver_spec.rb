require 'spec_helper'

module BeetleETL
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

    def items
      [a, b, c, d, e, f].shuffle
    end

    describe '#resolvables' do
      let(:resolver) { DependencyResolver.new(items) }

      it 'returns all items without dependencies when given an empty array' do
        expect(resolver.resolvables([])).to match_array([a])
      end

      it 'returns all items with met dependencies' do
        expect(resolver.resolvables([:a, :b, :c])).to match_array([d])
        expect(resolver.resolvables([:a, :b, :c, :d])).to match_array([e, f])
      end
    end

    context 'with cyclic or missing dependencies' do
      let(:cyclic) { Item.new(:a, Set.new([:b])) }

      it 'detects cyclic dependencies' do
        expect { DependencyResolver.new([cyclic, b]) }.to \
          raise_error(BeetleETL::UnsatisfiableDependenciesError)
      end

      it 'detects unsatisfiable dependencies' do
        expect { DependencyResolver.new([b]) }.to \
          raise_error(BeetleETL::UnsatisfiableDependenciesError)
      end
    end

  end
end
