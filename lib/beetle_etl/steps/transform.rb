module BeetleETL
  class Transform < Step

    def initialize(config, table_name, dependencies, query)
      super(config, table_name)
      @dependencies = dependencies
      @query = query
    end

    def dependencies
      Set.new(@dependencies.map { |d| self.class.step_name(d) })
    end

    def run
      database.execute(@query)
    end

  end
end

