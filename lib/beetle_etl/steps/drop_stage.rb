module BeetleETL
  class DropStage < Step

    def run
      database.execute <<-SQL
        DROP TABLE IF EXISTS #{stage_table_name_sql}
      SQL
    end

  end
end
