module BeetleETL

  UnsatisfiableDependenciesError = Class.new(StandardError)

  class DependencyResolver

    def initialize(items)
      @items = items
      check
    end

    def resolvables(resolved)
      @items.select do |item|
        (item.dependencies.subset?(resolved.to_set) || item.dependencies.empty?) && !resolved.include?(item.name)
      end
    end

    private

    def check
      items = @items.dup
      resolved = []

      until items.empty?
        resolved_names = resolved.flatten.map(&:name).to_set

        resolvable = items.select do |item|
          item.dependencies.subset?(resolved_names) || item.dependencies.empty?
        end

        raise UnsatisfiableDependenciesError if resolvable.empty?

        resolvable.each { |r| items.delete r }
        resolved << resolvable
      end
    end

  end
end
