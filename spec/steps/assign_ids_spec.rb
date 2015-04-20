require 'spec_helper'

module BeetleETL
  describe AssignIds do

    let(:external_source) { 'my_source' }
    let(:another_source) { 'another_source' }

    subject { AssignIds.new(:example_table) }

    before do
      BeetleETL.configure do |config|
        config.stage_schema = 'stage'
        config.external_source = external_source
        config.database = test_database
      end
    end

    describe '#dependencies' do
      it 'depends on TableDiff of the same table' do
        expect(subject.dependencies).to eql(['example_table: TableDiff'].to_set)
      end
    end

    describe '#run' do
      before do
        test_database.create_table(subject.stage_table_name.to_sym) do
          Integer :id
          String :external_id, size: 255
          String :transition, size: 255
        end

        test_database.create_table(:example_table) do
          primary_key :id
          String :external_id, size: 255
          String :external_source, size: 255
        end
      end

      it 'assigns ids for' do
        # - generated ones for new records
        # - mapped ones by external_id for existing records

        insert_into(:example_table).values(
          [ :external_id , :external_source ] ,
          [ 'a'          , external_source  ] ,
          [ 'b'          , external_source  ] ,
          [ 'c'          , external_source  ] ,
          [ 'd'          , another_source   ] ,
        )

        insert_into(subject.stage_table_name.to_sym).values(
          [ :external_id ] ,
          [ 'new value'  ] ,
          [ 'a'          ] ,
          [ 'b'          ] ,
          [ 'c'          ] ,
        )

        subject.run

        expect(subject.stage_table_name.to_sym).to have_values(
          [ :id , :external_id ] ,
          [ 1   , 'a'          ] ,
          [ 2   , 'b'          ] ,
          [ 3   , 'c'          ] ,
          [ 5   , 'new value'  ] ,
        )
      end
    end

  end
end
