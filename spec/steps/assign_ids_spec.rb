require 'spec_helper'

module BeetleETL
  describe AssignIds do

    let(:external_source) { 'my_source' }
    subject { AssignIds.new(:example_table) }

    before do
      BeetleETL.configure do |config|
        config.stage_schema = 'stage'
        config.external_source = external_source
        config.database = test_database
      end

      allow(BeetleETL).to receive(:state) { double(:state) }

      test_database.create_schema(:stage)
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

    describe '#dependencies' do
      it 'depends on TableDiff of the same table' do
        expect(subject.dependencies).to eql(['example_table: TableDiff'].to_set)
      end
    end

    describe '#run' do
      it 'runs all transitions' do
        %i(assign_new_ids map_existing_ids).each do |method|
          expect(subject).to receive(method)
        end

        subject.run
      end
    end

    describe '#assign_new_ids' do
      it 'generates new ids for newly created records' do
        insert_into(:example_table).values(
          [ :external_id , :external_source ] ,
          [ 'keep_id'    , external_source  ] ,
        )

        insert_into(subject.stage_table_name.to_sym).values(
          [ :external_id , :transition ] ,
          [ 'create_id'  , 'CREATE'    ] ,
          [ 'keep_id'    , 'KEEP'      ] ,
        )

        subject.assign_new_ids

        expect(subject.stage_table_name.to_sym).to have_values(
          [ :id , :external_id , :transition ] ,
          [ 2   , 'create_id'  , 'CREATE'    ] ,
          [ nil , 'keep_id'    , 'KEEP'      ] ,
        )
      end
    end

    describe '#map_existing_ids' do
      it 'assigns ids for existing records by their external id' do
        insert_into(:example_table).values(
          [ :external_id  , :external_source ] ,
          [ 'keep_id'     , external_source  ] ,
          [ 'update_id'   , external_source  ] ,
          [ 'delete_id'   , external_source  ] ,
          [ 'undelete_id' , external_source  ] ,
        )

        insert_into(subject.stage_table_name.to_sym).values(
          [ :external_id  , :transition ] ,
          [ 'create_id'   , 'CREATE'    ] ,
          [ 'keep_id'     , 'KEEP'      ] ,
          [ 'update_id'   , 'UPDATE'    ] ,
          [ 'delete_id'   , 'DELETE'    ] ,
          [ 'undelete_id' , 'UNDELETE'  ] ,
        )

        subject.map_existing_ids

        expect(subject.stage_table_name.to_sym).to have_values(
          [ :id , :external_id  , :transition ] ,
          [ nil , 'create_id'   , 'CREATE'    ] ,
          [ 1   , 'keep_id'     , 'KEEP'      ] ,
          [ 2   , 'update_id'   , 'UPDATE'    ] ,
          [ 3   , 'delete_id'   , 'DELETE'    ] ,
          [ 4   , 'undelete_id' , 'UNDELETE'  ] ,
        )
      end
    end

  end
end
