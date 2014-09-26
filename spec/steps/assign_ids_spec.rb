require 'spec_helper'

module BeetleETL
  describe AssignIds do

    let(:run_id) { 1 }
    let(:external_source) { 'my_source' }
    subject { AssignIds.new(:example_table) }

    before do
      BeetleETL.configure do |config|
        config.stage_schema = 'stage'
        config.external_source = external_source
        config.database = test_database
      end

      allow(BeetleETL).to receive(:state) { double(:state, run_id: run_id) }

      test_database.create_schema(:stage)
      test_database.create_table(:stage__example_table) do
        Integer :id
        Integer :import_run_id
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

        insert_into(:stage__example_table).values(
          [ :import_run_id , :external_id , :transition ] ,
          [ run_id         , 'create_id'  , 'CREATE'    ] ,
          [ run_id         , 'keep_id'    , 'KEEP'      ] ,
        )

        subject.assign_new_ids

        expect(:stage__example_table).to have_values(
          [ :id , :import_run_id , :external_id , :transition ] ,
          [ 2   , run_id         , 'create_id'  , 'CREATE'    ] ,
          [ nil , run_id         , 'keep_id'    , 'KEEP'      ] ,
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

        insert_into(:stage__example_table).values(
          [ :import_run_id , :external_id  , :transition ] ,
          [ run_id         , 'create_id'   , 'CREATE'    ] ,
          [ run_id         , 'keep_id'     , 'KEEP'      ] ,
          [ run_id         , 'update_id'   , 'UPDATE'    ] ,
          [ run_id         , 'delete_id'   , 'DELETE'    ] ,
          [ run_id         , 'undelete_id' , 'UNDELETE'  ] ,
        )

        subject.map_existing_ids

        expect(:stage__example_table).to have_values(
          [ :id , :import_run_id , :external_id  , :transition ] ,
          [ nil , run_id         , 'create_id'   , 'CREATE'    ] ,
          [ 1   , run_id         , 'keep_id'     , 'KEEP'      ] ,
          [ 2   , run_id         , 'update_id'   , 'UPDATE'    ] ,
          [ 3   , run_id         , 'delete_id'   , 'DELETE'    ] ,
          [ 4   , run_id         , 'undelete_id' , 'UNDELETE'  ] ,
        )
      end
    end

  end
end
