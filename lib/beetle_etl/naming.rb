require 'digest'

module BeetleETL
  module Naming

    extend self

    def stage_table_name(table_name = nil)
      name = (table_name || @table_name).to_s
      digest = Digest::MD5.hexdigest(name)
      "#{BeetleETL.config.external_source}-#{name}-#{digest}"[0, 63]
    end

    def stage_table_name_sql(table_name = nil)
      %Q("#{stage_table_name(table_name)}")
    end

    def target_table_name(table_name = nil)
      name = (table_name || @table_name).to_s
      [target_schema, name].compact.join('.')
    end

    def target_table_name_sql(table_name = nil)
      name = (table_name || @table_name).to_s
      target_table_name= [target_schema, name].compact.join('"."')
      %Q("#{target_table_name}")
    end

    private

    def target_schema
      target_schema = BeetleETL.config.target_schema
      target_schema != 'public' ? target_schema : nil
    end

  end
end
