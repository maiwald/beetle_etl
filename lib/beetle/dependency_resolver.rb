module Beetle

  UnsatisfiableDependenciesError = Class.new(StandardError)

  class DependencyResolver

    def initialize(items)
      items = items.dup
      @resolved = []

      while not items.empty?
        resolved_names = resolved.flatten.map(&:table_name).to_set

        resolvable = items.select do |item|
          item.dependencies.subset?(resolved_names) || item.dependencies.empty?
        end

        raise UnsatisfiableDependenciesError if resolvable.empty?

        resolvable.each { |r| items.delete r }
        @resolved << resolvable
      end
    end

    def resolved
      @resolved.flatten
    end

    def resolved_in_tiers
      @resolved
    end

  end
end
