require "spec_helper"

shared_examples "database adapter" do
  before do
    test_database.run <<-SQL
      CREATE SCHEMA foo;
      CREATE TABLE foo.persons (
        id int,
        first_name varchar(255),
        last_name varchar(255)
      );
    SQL
  end

  after do
    test_database.run <<-SQL
      DROP SCHEMA foo CASCADE;
    SQL
  end

  describe "#execute" do
    it "executes SQL" do
      adapter.execute <<-SQL
          INSERT INTO foo.persons VALUES (1, 'hugo', 'warzenkopp');
      SQL

      expect(Sequel.qualify("foo", "persons")).to have_values(
        [ :id , :first_name , :last_name   ],
        [ 1   , "hugo"      , "warzenkopp" ]
      )
    end
  end

  describe "#column_names" do
    it "returns a tables column names" do
      expect(adapter.column_names("foo", "persons")).to match_array([
        :id, :first_name, :last_name
      ])
    end
  end

  describe "#column_types" do
    it "returns a tables column names" do
      expect(adapter.column_types("foo", "persons")).to match({
        id: 'integer',
        first_name: 'character varying(255)',
        last_name: 'character varying(255)'
      })
    end
  end

  describe "#table_exists?" do
    it "returns whether a table exists" do
      expect(adapter.table_exists?("foo", "persons")).to eql(true)
      expect(adapter.table_exists?("foo", "persons200")).to eql(false)
    end
  end
end
