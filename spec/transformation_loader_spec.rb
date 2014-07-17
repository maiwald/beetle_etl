require 'spec_helper'
require 'tempfile'

module Beetle
  describe TransformationLoader do

    before do
      @data_file = tempfile_with_contents <<-FILE
        import :foo do
          'foo'
        end

        import :bar do
          'bar'
        end
      FILE
    end

    describe '#load' do
      it 'loads runlist entries from the data file' do
        expect(Transformation).to receive(:new) do |table_name, config|
          expect(table_name.to_s).to eql(config.call)
        end.exactly(2).times

        subject.load(@data_file.path)
      end

      it 'adds every runlist entry to the entries array' do
        allow(Transformation).to receive(:new) do |table_name, config|
          table_name
        end

        transformations = subject.load(@data_file.path)

        expect(transformations).to eql(%i[foo bar])
      end
    end

    def tempfile_with_contents(contents)
      Tempfile.new('transform').tap do |file|
        file.write(contents)
        file.close
      end
    end

  end
end
