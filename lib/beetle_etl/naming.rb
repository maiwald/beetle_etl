require 'digest'

module BeetleETL
  module Naming

    extend self

    def stage_table_name(external_source, table_name)
      digest = Digest::MD5.hexdigest(table_name.to_s)
      "#{external_source.to_s}-#{table_name.to_s}-#{digest}"[0, 63]
    end

    def stage_table_name_sql(external_source, table_name)
      %Q("#{stage_table_name(external_source, table_name)}")
    end

    def target_table_name(target_schema, table_name)
      schema = target_schema ? target_schema.to_s : nil
      [schema, table_name.to_s].compact.join('.')
    end

    def target_table_name_sql(target_schema, table_name)
      %Q("#{target_table_name(target_schema, table_name)}")
    end

  end
end
