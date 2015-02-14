module BeetleETL
  class DropStage < Step

    def dependencies
      Set.new
    end

    def run
      database.execute <<-SQL
        DROP TABLE IF EXISTS #{stage_table_name_sql}
      SQL
    end

  end
end
