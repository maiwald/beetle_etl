module BeetleETL
  module Testing

    TargetTableNotFoundError = Class.new(StandardError)
    NoTransformationFoundError = Class.new(StandardError)

    def with_stage_tables_for(*table_names, &block)
      table_names.each do |table_name|
        unless BeetleETL.database.table_exists?(table_name)
          raise TargetTableNotFoundError.new <<-MSG
            Missing target table "#{table_name}".
            In order to create stage tables, BeetleETL requires the target tables to exist because they provide the column definitions.
          MSG
        end
      end

      import = Import.new
      begin
        import.setup
        block.call
      ensure
        import.cleanup
      end
    end

    def run_transformation(table_name)
      transformations = TransformationLoader.new.load

      unless transformations.map(&:table_name).include?(table_name)
        raise NoTransformationFoundError.new <<-MSG
          No transformation definition found for table "#{table_name}".
        MSG
      end

      transformation = transformations.find { |t| t.table_name == table_name }
      transform = Transform.new(transformation.table_name, transformation.dependencies, transformation.query)
      transform.run
    end


    def stage_table_name(table_name)
      BeetleETL::Naming.stage_table_name(table_name)
    end

  end
end
