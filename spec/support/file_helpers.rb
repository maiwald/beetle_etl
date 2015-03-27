require "tempfile"

module SpecSupport
  module FileHelpers

    def tempfile_with_contents(contents)
      ::Tempfile.new('transform').tap do |file|
        file.write(contents)
        file.close
      end
    end

  end
end
