module Beetle
  class Transform < Step

    attr_reader :query

    def initialize(table_name, query)
      super(table_name)
      @query = query
    end

    def run
      database.run(query)
    end

  end
end

