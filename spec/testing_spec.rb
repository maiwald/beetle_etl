require "spec_helper"
require "beetle_etl/testing"

describe "BeetleETL:Testing" do

  include BeetleETL::Testing

  before do
    data_file = tempfile_with_contents <<-'FILE'
      import :some_table do
        columns :some_attribute
      end

      import :organisations do
        references :some_table, on: :some_table_id
        columns :name, :address

        query <<-SQL
          INSERT INTO #{stage_table} (external_id, address, name)
          VALUES ('external_id', 'address', 'name')
        SQL
      end
    FILE

    BeetleETL.configure do |config|
      config.database = test_database
      config.transformation_file = data_file.path
    end
  end

  context "with properly defined target tables" do
    before do
      test_database.create_table :some_table do
        primary_key :id
        String :external_id, size: 255
        String :some_attribute, size: 255
      end

      test_database.create_table :organisations do
        primary_key :id
        String :external_id, size: 255
        String :name, size: 255
        String :address, size: 255
      end
    end

    it "makes stage tables available in the block" do
      with_stage_tables_for(:organisations, :some_table) do
        expect(test_database.table_exists?(stage_table_name(:organisations))).to be_truthy
        expect(test_database.table_exists?(stage_table_name(:some_table))).to be_truthy
      end

      expect(test_database.table_exists?(stage_table_name(:organisations))).to be_falsey
      expect(test_database.table_exists?(stage_table_name(:some_table))).to be_falsey
    end

    it "allows the transformation to be run insiede the block" do
      with_stage_tables_for(:organisations, :some_table) do
        run_transformation(:organisations)

        expect(stage_table_name(:organisations)).to have_values(
          [ :external_id  , :address  , :name  ] ,
          [ "external_id" , "address" , "name" ]
        )
      end
    end

  end

  it "raises an error if the target table cannot be found" do
    expect do
      with_stage_tables_for(:organisations)
    end.to raise_error(BeetleETL::Testing::TargetTableNotFoundError)
  end
end
