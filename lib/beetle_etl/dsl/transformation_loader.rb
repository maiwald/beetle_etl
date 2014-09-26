module BeetleETL
  module TransformationLoader
    extend self

    def load
      @transformations = []

      File.open(BeetleETL.config.transformation_file, 'r') do |file|
        instance_eval file.read
      end

      @transformations
    end

    private

    def import(table_name, &setup)
      @transformations << Transformation.new(table_name, setup)
    end

  end
end
