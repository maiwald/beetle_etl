require 'spec_helper'

module BeetleETL
  describe TableDiff do

    let(:external_source) { 'my_source' }
    let(:config) do
      Configuration.new.tap do |c|
        c.external_source = external_source
        c.database = test_database
      end
    end

    let(:time_in_past) { Time.new(2020, 3, 23) }

    subject { TableDiff.new(config, :example_table) }

    before do
      test_database.create_table(subject.stage_table_name.to_sym) do
        Integer :id
        String :external_id, size: 255
        String :transition, size: 20

        String :external_foo_id, size: 255
        Integer :foo_id

        String :payload, size: 255
      end

      test_database.create_table(:example_table) do
        primary_key :id
        String :external_id, size: 255
        String :external_source, size: 255
        DateTime :deleted_at

        String :payload, size: 255
        String :ignored_attribute, size: 255
        Integer :foo_id
      end
    end

    describe '#depenencies' do
      it 'depends on MapRelations of the same table' do
        expect(subject.dependencies).to eql(['example_table: MapRelations'].to_set)
      end
    end

    describe '#run' do
      it 'runs all transitions' do
        %w(create update delete reinstate keep).each do |transition|
          expect(subject).to receive(:"transition_#{transition}")
        end

        subject.run
      end
    end

    describe '#transition_create' do
      it 'assigns CREATE to new records' do

        insert_into(:example_table).values(
          [ :id , :external_id , :external_source , :payload           , :ignored_attribute , :foo_id , :deleted_at  ] ,
          [ 1   , 'existing'   , external_source  , 'existing content' , 'ignored content'  , 1       , nil          ] ,
          [ 2   , 'deleted'    , external_source  , 'deleted content'  , 'ignored content'  , 2       , time_in_past ] ,
        )

        test_database.run "SELECT setval('public.example_table_id_seq', 99)"

        insert_into(subject.stage_table_name.to_sym).values(
          [ :external_id ] ,
          [ 'created'    ] ,
          [ 'existing'   ] ,
        )

        subject.transition_create

        expect(subject.stage_table_name.to_sym).to have_values(
          [ :external_id , :id , :transition ] ,
          [ 'created'    , 100 , 'CREATE'    ] ,
          [ 'existing'   , nil , nil         ] ,
        )
      end
    end

    describe '#transition_update' do
      it 'assigns UPDATE to non-deleted records with changed values comparing all columns
        except externald_*_id columns and columns not contained in the stage table' do

        insert_into(:example_table).values(
          [ :id , :external_id , :external_source , :payload           , :ignored_attribute , :foo_id , :deleted_at  ] ,
          [ 1   , 'existing_1' , external_source  , 'existing content' , 'ignored content'  , 1       , nil          ] ,
          [ 2   , 'existing_2' , external_source  , 'existing content' , 'ignored content'  , 2       , nil          ] ,
          [ 3   , 'deleted'    , external_source  , 'deleted content'  , 'ignored content'  , 3       , time_in_past ] ,
        )

        insert_into(subject.stage_table_name.to_sym).values(
          [ :external_id , :payload           , :foo_id , :external_foo_id ] ,
          [ 'existing_1' , 'updated content'  , 1       , 'ignored_column' ] ,
          [ 'existing_2' , 'existing content' , 4       , 'ignored_column' ] ,
          [ 'deleted'    , 'updated content'  , 3       , 'ignored_column' ] ,
        )

        subject.transition_update

        expect(subject.stage_table_name.to_sym).to have_values(
          [ :external_id , :id , :transition ] ,
          [ 'existing_1' , 1   , 'UPDATE'    ] ,
          [ 'existing_2' , 2   , 'UPDATE'    ] ,
          [ 'deleted'    , nil , nil         ] ,
        )
      end
    end

    describe 'transition_delete' do
      it 'creates records with DELETE that no loger exist in the stage table for the given run' do
        insert_into(:example_table).values(
          [ :id , :external_id , :external_source , :payload           , :ignored_attribute , :foo_id , :deleted_at  ] ,
          [ 1   , 'existing'   , external_source  , 'existing content' , 'ignored content'  , 1       , nil          ] ,
          [ 2   , 'deleted'    , external_source  , 'deleted content'  , 'ignored content'  , 2       , time_in_past ] ,
        )

        subject.transition_delete

        expect(subject.stage_table_name.to_sym).to have_values(
          [ :id , :transition ] ,
          [ 1   , 'DELETE'    ] ,
        )
      end
    end

    describe 'transition_reinstate' do
      it 'assigns REINSTATE to previously deleted records' do
        insert_into(:example_table).values(
          [ :id , :external_id , :external_source , :payload           , :ignored_attribute , :foo_id , :deleted_at  ] ,
          [ 1   , 'existing'   , external_source  , 'existing content' , 'ignored content'  , 1       , nil          ] ,
          [ 2   , 'deleted'    , external_source  , 'deleted content'  , 'ignored content'  , 2       , time_in_past ] ,
        )

        insert_into(subject.stage_table_name.to_sym).values(
          [ :external_id , :payload          , :foo_id , :external_foo_id ] ,
          [ 'existing'   , 'updated content' , 1       , 'ignored_column' ] ,
          [ 'deleted'    , 'updated content' , 2       , 'ignored_column' ] ,
        )

        subject.transition_reinstate

        expect(subject.stage_table_name.to_sym).to have_values(
          [ :external_id , :id , :transition  ] ,
          [ 'existing'   , nil , nil          ] ,
          [ 'deleted'    , 2   , 'REINSTATE'  ] ,
        )
      end
    end

    describe '#transition_keep' do
      it 'assigns KEEP to unchanged records' do

        insert_into(:example_table).values(
          [ :id , :external_id , :external_source , :payload           , :ignored_attribute , :foo_id , :deleted_at ] ,
          [ 1   , 'existing'   , external_source  , 'existing content' , 'ignored content'  , 1       , nil         ] ,
          [ 2   , 'deleted'    , external_source  , 'deleted content'  , 'ignored content'  , 2       , time_in_past   ] ,
        )

        insert_into(subject.stage_table_name.to_sym).values(
          [ :external_id , :payload           , :foo_id ] ,
          [ 'created'    , nil                , nil     ] ,
          [ 'existing'   , 'existing content' , 1       ] ,
        )

        subject.transition_keep

        expect(subject.stage_table_name.to_sym).to have_values(
          [ :external_id , :id , :transition ] ,
          [ 'created'    , nil , nil         ] ,
          [ 'existing'   , 1   , 'KEEP'      ] ,
        )
      end
    end

  end
end
