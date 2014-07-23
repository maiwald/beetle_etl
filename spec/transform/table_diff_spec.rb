require 'spec_helper'

module Beetle
  describe TableDiff do

    let(:run_id) { 1 }
    subject { TableDiff.new('example_table') }

    before do
      test_database.create_schema(:stage)
      test_database.create_table(:stage__example_table) do
        Integer :import_run_id
        String :external_id, size: 255
        String :external_source, size: 255
        String :transition, size: 20
        index [:import_run_id, :external_id, :external_source], unique: true

        String :external_foo_id, size: 255
        Integer :foo_id

        String :payload, size: 255
      end

      test_database.create_table(:example_table) do
        Integer :id
        String :external_id, size: 255
        String :external_source, size: 255
        index [:external_id, :external_source], unique: true

        String :payload, size: 255
        String :ignored_attribute, size: 255

        Integer :foo_id
      end

      Beetle.configure do |config|
        config.stage_schema = 'stage'
        config.external_source = 'my_source'
        config.database = test_database
      end

      allow(Beetle).to receive(:state) { double(:state, run_id: run_id) }
    end

    describe '#transition_create' do
      it 'assigns the transition CREATE to new records' do
        insert_into(:example_table).values(
          [ :external_id , :external_source , :foo_id ] ,
          [ 'existing'   , 'my_source'      , 1       ] ,
        )

        insert_into(:stage__example_table).values(
          [ :import_run_id , :external_id , :external_source ] ,
          [ run_id         , 'created'    , 'my_source'      ] ,
          [ run_id         , 'existing'   , 'my_source'      ] ,
        )

        subject.transition_create

        expect(:stage__example_table).to have_values(
          [ :import_run_id , :external_id , :external_source , :transition ] ,
          [ run_id         , 'created'    , 'my_source'      , 'CREATE'    ] ,
          [ run_id         , 'existing'   , 'my_source'      , nil         ] ,
        )

      end
    end

    describe 'transition_keep' do
      it 'assigns the transition KEEP if the record already exists comparing all columns
        except externald_*_id columns and columns not contained in the stage table' do

        insert_into(:example_table).values(
          [ :external_id , :external_source , :payload  , :ignored_attribute , :foo_id ] ,
          [ 'existing'   , 'my_source'      , 'content' , 'ignored content'  , 1       ] ,
        )

        insert_into(:stage__example_table).values(
          [ :import_run_id , :external_id , :external_source , :payload  , :foo_id , :external_foo_id ] ,
          [ run_id         , 'created'    , 'my_source'      , nil       , 1       , nil              ] ,
          [ run_id         , 'existing'   , 'my_source'      , 'content' , 1       , 'ignored column' ] ,
        )

        subject.transition_keep

        expect(:stage__example_table).to have_values(
          [ :import_run_id , :external_id , :external_source , :payload  , :transition ] ,
          [ run_id         , 'created'    , 'my_source'      , nil       , nil         ] ,
          [ run_id         , 'existing'   , 'my_source'      , 'content' , 'KEEP'      ] ,
        )
      end
    end

    describe 'transition_undelete'
    describe 'transition_update'
    describe 'transition_delete'
    describe 'transition_keep_deleted'
  end
end
