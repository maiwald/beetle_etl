require 'spec_helper'

module Beetle
  describe DependencyResolver do

    TransformationDouble = Struct.new(:table_name, :dependencies)

    let(:t1) { TransformationDouble.new(:foo, Set.new) }
    let(:t2) { TransformationDouble.new(:bar, Set.new([:foo])) }
    let(:t3) { TransformationDouble.new(:abc, Set.new([:bar])) }
    let(:t4) { TransformationDouble.new(:baz, Set.new([:foo, :bar])) }

    let(:cyclic) { TransformationDouble.new(:foo, Set.new([:bar])) }
    let(:transitive_cyclic) { TransformationDouble.new(:foo, Set.new([:abc])) }

    it 'returns an empty array if given an empty array' do
      expect(DependencyResolver.resolve([])).to eql([])
    end

    it 'orderes transformations by their dependencies' do
      result = DependencyResolver.resolve([t3, t1, t4, t2])
      expect(result).to eql([t1, t2, t3, t4])
    end

    context 'exceptional states' do
      it 'detects cyclic dependencies' do
        expect { DependencyResolver.resolve([cyclic, t2]) }.to \
          raise_error(Beetle::UnsatisfiableDependenciesError)
      end

      it 'detects transitive cyclic dependencies' do
        expect { DependencyResolver.resolve([t2, transitive_cyclic, t3]) }.to \
          raise_error(Beetle::UnsatisfiableDependenciesError)
      end

      it 'detects unsatisfiable dependencies' do
        expect { DependencyResolver.resolve([t2]) }.to \
          raise_error(Beetle::UnsatisfiableDependenciesError)
      end
    end

  end
end
