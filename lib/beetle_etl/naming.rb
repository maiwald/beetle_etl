require 'digest'

module BeetleETL
  module Naming

    extend self

    def stage_table_name(table_name = nil)
      name = (table_name || @table_name).to_s
      digest = Digest::MD5.hexdigest(name)
      "#{name}-#{digest}"[0, 63]
    end

    def stage_table_name_sql(table_name = nil)
      %Q("#{stage_table_name(table_name)}")
    end

    def public_table_name(table_name = nil)
      name = (table_name || @table_name).to_s
      [public_schema, name].compact.join('.')
    end

    def public_table_name_sql(table_name = nil)
      name = (table_name || @table_name).to_s
      public_table_name= [public_schema, name].compact.join('"."')
      %Q("#{public_table_name}")
    end

    private

    def public_schema
      public_schema = BeetleETL.config.public_schema
      public_schema != 'public' ? public_schema : nil
    end

  end
end
