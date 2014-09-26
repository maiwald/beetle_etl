module BeetleETL
  class Transform < Step

    attr_reader :query

    def initialize(table_name, dependencies, query)
      super(table_name)
      @dependencies = dependencies
      @query = query
    end

    def dependencies
      Set.new(@dependencies.map { |d| self.class.step_name(d) })
    end

    def run
      database.run(query)
    end

  end
end

