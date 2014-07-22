module Beetle

  UnsatisfiableDependenciesError = Class.new(StandardError)

  module DependencyResolver
    extend self

    def resolve (items)
      items = items.dup
      resolved = []

      while not items.empty?
        resolved_names = resolved.map(&:table_name).to_set

        resolvable = items.select do |item|
          item.dependencies.subset?(resolved_names) || item.dependencies.empty?
        end

        raise UnsatisfiableDependenciesError if resolvable.empty?

        resolvable.each { |r| items.delete r }
        resolved += resolvable
      end

      return resolved
    end

  end
end
