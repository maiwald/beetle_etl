require 'spec_helper'

module BeetleETL
  describe TransformationLoader do

    subject { TransformationLoader.new }

    before do
      data_file = tempfile_with_contents <<-FILE
        import :foo do
          'foo'
        end

        import :bar do
          'bar'
        end

        helpers do
          "baz"
        end
      FILE

      BeetleETL.configure do |config|
        config.transformation_file = data_file.path
      end
    end

    describe '#load' do
      it 'loads transformations from the data file' do
        expect(Transformation).to receive(:new) do |table_name, config, helpers|
          expect(table_name.to_s).to eql(config.call)
          expect(helpers.call).to eql("baz")
        end.exactly(2).times

        subject.load
      end

      it 'returns the list of transformations' do
        allow(Transformation).to receive(:new) do |table_name, config, helpers|
          table_name
        end

        transformations = subject.load

        expect(transformations).to eql(%i[foo bar])
      end
    end

  end
end
