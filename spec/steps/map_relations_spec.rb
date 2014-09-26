require 'spec_helper'

module BeetleETL
  describe MapRelations do

    let(:run_id) { 1 }
    let(:previous_run_id) { 5000 }

    before do
      BeetleETL.configure do |config|
        config.stage_schema = 'stage'
        config.external_source = 'my_source'
        config.database = test_database
      end

      allow(BeetleETL).to receive(:state) { double(:state, run_id: run_id) }

      test_database.create_schema(:stage)
      test_database.create_table(:stage__dependee_a) do
        Integer :import_run_id
        Integer :id
        String :external_id, size: 255
      end

      test_database.create_table(:stage__dependee_b) do
        Integer :import_run_id
        Integer :id
        String :external_id, size: 255
      end

      test_database.create_table(:stage__depender) do
        Integer :import_run_id
        String :external_id, size: 255

        String :external_dependee_a_id
        Integer :dependee_a_id

        String :external_dependee_b_id
        Integer :dependee_b_id
      end
    end

    describe '#depenencies' do
      it 'depends on Transform of the same table and AssignIds of its dependees' do
        relations = {
          dependee_a_id: :dependee_a,
          dependee_b_id: :dependee_b,
        }

        expect(MapRelations.new(:depender, relations).dependencies).to eql(
          [
            'dependee_a: AssignIds',
            'dependee_b: AssignIds',
            'depender: Transform',
          ].to_set
        )
      end
    end

    describe '#run' do
      it 'maps external foreign key references to id references ' do
        insert_into(:stage__dependee_a).values(
          [ :import_run_id  , :id , :external_id ] ,
          [ run_id          , 1   , 'a_id'       ] ,
          [ previous_run_id , 2   , 'a_id'       ] ,
        )

        insert_into(:stage__dependee_b).values(
          [ :import_run_id , :id , :external_id ] ,
          [ run_id         , 26  , 'b_id'       ] ,
        )

        insert_into(:stage__depender).values(
          [ :import_run_id , :external_dependee_a_id , :external_dependee_b_id ] ,
          [ run_id         , 'a_id'                  , 'b_id'                  ] ,
        )

        relations = {
          dependee_a_id: :dependee_a,
          dependee_b_id: :dependee_b,
        }

        MapRelations.new(:depender, relations).run

        expect(:stage__depender).to have_values(
          [ :import_run_id , :dependee_a_id , :dependee_b_id ] ,
          [ run_id         , 1              , 26             ] ,
        )
      end
    end
  end
end
