module BeetleETL
  module Testing

    require 'beetle_etl/testing/test_wrapper'

    TargetTableNotFoundError = Class.new(StandardError)
    NoTransformationFoundError = Class.new(StandardError)

    def self.configure
      @@config = Configuration.new
      yield(@@config)
    end

    def with_stage_tables_for(*table_names, &block)
      table_names.each do |table_name|
        unless @@config.database.table_exists?(table_name)
          raise TargetTableNotFoundError.new <<-MSG
            Missing target table "#{table_name}".
            In order to create stage tables, BeetleETL requires the target tables to exist because they provide the column definitions.
          MSG
        end
      end

      test_wrapper = TestWrapper.new(@@config, table_names)
      test_wrapper.run block
    end

    def run_transformation(table_name)
      transformations = TransformationLoader.new(@@config).load

      unless transformations.map(&:table_name).include?(table_name)
        raise NoTransformationFoundError.new <<-MSG
          No transformation definition found for table "#{table_name}".
        MSG
      end

      transformation = transformations.find { |t| t.table_name == table_name }
      transform = Transform.new(@@config, transformation.table_name, transformation.dependencies, transformation.query)
      transform.run
    end


    def stage_table_name(table_name)
      BeetleETL::Naming.stage_table_name(@@config.external_source, table_name)
    end

  end
end
