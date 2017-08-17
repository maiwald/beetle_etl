module BeetleETL
  class DropStage < Step

    def run
      database.execute <<-SQL
        DROP TABLE IF EXISTS "#{target_schema}"."#{stage_table_name}";
      SQL
    end

  end
end
