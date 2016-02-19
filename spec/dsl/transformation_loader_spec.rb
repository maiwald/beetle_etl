require 'spec_helper'

module BeetleETL
  describe TransformationLoader do

    let(:config) do
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

      Configuration.new.tap do |c|
        c.transformation_file = data_file.path
      end
    end

    subject { TransformationLoader.new(config) }

    describe '#load' do
      it 'loads transformations from the data file' do
        expect(Transformation).to receive(:new) do |configuration, table_name, setup, helpers|
          expect(configuration).to eql(config)
          expect(table_name.to_s).to eql(setup.call)
          expect(helpers.call).to eql("baz")
        end.exactly(2).times

        subject.load
      end

      it 'returns the list of transformations' do
        allow(Transformation).to receive(:new) do |configuration, table_name, setup, helpers|
          table_name
        end

        transformations = subject.load

        expect(transformations).to eql(%i[foo bar])
      end
    end

  end
end
