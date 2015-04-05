module BeetleETL
  module Testing
    class TestWrapper < Struct.new(:table_names)

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
          CreateStage.new(t.table_name, t.relations, t.column_names).run
        end
      end

      def drop_stages
        transformations.each do |t|
          DropStage.new(t.table_name).run
        end
      end

      def transformations
        @transformations ||= TransformationLoader.new.load.find_all do |transformation|
          table_names.include? transformation.table_name
        end
      end

    end
  end
end
