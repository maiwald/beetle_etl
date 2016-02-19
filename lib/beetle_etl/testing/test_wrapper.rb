module BeetleETL
  module Testing
    class TestWrapper < Struct.new(:config, :table_names)

      def run(block)
        begin
          create_stages
          block.call
        ensure
          drop_stages
        end
      end

      private

      def create_stages
        transformations.each do |t|
          CreateStage.new(config, t.table_name, t.relations, t.column_names).run
        end
      end

      def drop_stages
        transformations.each do |t|
          DropStage.new(config, t.table_name).run
        end
      end

      def transformations
        @transformations ||= TransformationLoader.new(config).load.find_all do |transformation|
          table_names.include? transformation.table_name
        end
      end

    end
  end
end
