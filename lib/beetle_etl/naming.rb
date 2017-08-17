require 'digest'

module BeetleETL
  module Naming

    extend self

    def stage_table_name(external_source, table_name)
      digest = Digest::MD5.hexdigest(table_name.to_s)
      "#{external_source.to_s}-#{table_name.to_s}-#{digest}"[0, 63]
    end

  end
end
