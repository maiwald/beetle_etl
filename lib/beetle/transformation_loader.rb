module Beetle
  module TransformationLoader

    extend self

    def load(data_file)
      @transformations = []

      File.open(data_file, 'r') do |file|
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
