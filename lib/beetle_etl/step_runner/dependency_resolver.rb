module BeetleETL

  UnsatisfiableDependenciesError = Class.new(StandardError)

  class DependencyResolver

    def initialize(items)
      @items = items
      check
    end

    def resolvables(resolved)
      @items.select do |item|
        !resolved.include?(item.name) && all_dependencies_met?(item, resolved)
      end
    end

    private

    def check
      items = @items.dup
      resolved = []

      until items.empty?
        resolvables = items.select { |item| all_dependencies_met?(item, resolved.map(&:name)) }
        raise UnsatisfiableDependenciesError if resolvables.empty?
        resolvables.each { |r| resolved << items.delete(r) }
      end
    end

    def all_dependencies_met?(item, resolved)
      item.dependencies.empty? || item.dependencies.subset?(resolved.to_set)
    end

  end
end
