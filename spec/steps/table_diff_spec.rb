require 'spec_helper'

require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/numeric/time'

module BeetleETL
  describe TableDiff do

    let(:external_source) { 'my_source' }

    subject { TableDiff.new(:example_table) }

    before do
      BeetleETL.configure do |config|
        config.external_source = external_source
        config.database = test_database
      end

      test_database.create_table(subject.stage_table_name.to_sym) do
        String :external_id, size: 255
        String :transition, size: 20

        String :external_foo_id, size: 255
        Integer :foo_id

        String :payload, size: 255
      end

      test_database.create_table(:example_table) do
        Integer :id
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
        %w(create keep update delete reinstate).each do |transition|
          expect(subject).to receive(:"transition_#{transition}")
        end

        subject.run
      end
    end

    describe '#transition_create' do
      it 'assigns CREATE to new records' do

        insert_into(:example_table).values(
          [ :external_id , :external_source , :payload           , :ignored_attribute , :foo_id , :deleted_at ] ,
          [ 'existing'   , external_source  , 'existing content' , 'ignored content'  , 1       , nil         ] ,
          [ 'deleted'    , external_source  , 'deleted content'  , 'ignored content'  , 2       , 1.day.ago   ] ,
        )

        insert_into(subject.stage_table_name.to_sym).values(
          [ :external_id ] ,
          [ 'created'    ] ,
          [ 'existing'   ] ,
        )

        subject.transition_create

        insert_into(subject.stage_table_name.to_sym).values(
          [ :external_id , :transition ] ,
          [ 'created'    , 'CREATE'    ] ,
          [ 'existing'   , nil         ] ,
        )
      end
    end

    describe 'transition_keep' do
      it 'assigns KEEP if the record already exists and is not deleted, comparing all columns
        except externald_*_id columns and columns not contained in the stage table' do

        insert_into(:example_table).values(
          [ :external_id , :external_source , :payload           , :ignored_attribute , :foo_id , :deleted_at ] ,
          [ 'existing'   , external_source  , 'existing content' , 'ignored content'  , 1       , nil         ] ,
          [ 'deleted'    , external_source  , 'deleted content'  , 'ignored content'  , 2       , 1.day.ago   ] ,
        )

        insert_into(subject.stage_table_name.to_sym).values(
          [ :external_id , :payload           , :foo_id , :external_foo_id ] ,
          [ 'existing'   , 'existing content' , 1       , 'ignored column' ] ,
          [ 'deleted'    , 'deleted content'  , 2       , 'ignored column' ] ,
        )

        subject.transition_keep

        expect(subject.stage_table_name.to_sym).to have_values(
          [ :external_id , :transition ] ,
          [ 'existing'   , 'KEEP'      ] ,
          [ 'deleted'    , nil         ] ,
        )
      end
    end

    describe '#transition_update' do
      it 'assigns UPDATE to non-deleted records with changed values comparing all columns
        except externald_*_id columns and columns not contained in the stage table' do

        insert_into(:example_table).values(
          [ :external_id , :external_source , :payload           , :ignored_attribute , :foo_id , :deleted_at ] ,
          [ 'existing_1' , external_source  , 'existing content' , 'ignored content'  , 1       , nil         ] ,
          [ 'existing_2' , external_source  , 'existing content' , 'ignored content'  , 2       , nil         ] ,
          [ 'deleted'    , external_source  , 'deleted content'  , 'ignored content'  , 3       , 1.day.ago   ] ,
        )

        insert_into(subject.stage_table_name.to_sym).values(
          [ :external_id , :payload           , :foo_id , :external_foo_id ] ,
          [ 'existing_1' , 'updated content'  , 1       , 'ignored_column' ] ,
          [ 'existing_2' , 'existing content' , 4       , 'ignored_column' ] ,
          [ 'deleted'    , 'updated content'  , 3       , 'ignored_column' ] ,
        )

        subject.transition_update

        expect(subject.stage_table_name.to_sym).to have_values(
          [ :external_id , :transition ] ,
          [ 'existing_1' , 'UPDATE'    ] ,
          [ 'existing_2' , 'UPDATE'    ] ,
          [ 'deleted'    , nil         ] ,
        )
      end
    end

    describe 'transition_delete' do
      it 'creates records with DELETE that no loger exist in the stage table for the given run' do
        insert_into(:example_table).values(
          [ :external_id , :external_source , :payload           , :ignored_attribute , :foo_id , :deleted_at ] ,
          [ 'existing'   , external_source  , 'existing content' , 'ignored content'  , 1       , nil         ] ,
          [ 'deleted'    , external_source  , 'deleted content'  , 'ignored content'  , 2       , 1.day.ago   ] ,
        )

        subject.transition_delete

        expect(subject.stage_table_name.to_sym).to have_values(
          [ :external_id , :transition ] ,
          [ 'existing'   , 'DELETE'    ] ,
        )
      end
    end

    describe 'transition_reinstate' do
      it 'assigns REINSTATE to previously deleted records' do
        insert_into(:example_table).values(
          [ :external_id , :external_source , :payload           , :ignored_attribute , :foo_id , :deleted_at ] ,
          [ 'existing'   , external_source  , 'existing content' , 'ignored content'  , 1       , nil         ] ,
          [ 'deleted'    , external_source  , 'deleted content'  , 'ignored content'  , 2       , 1.day.ago   ] ,
        )

        insert_into(subject.stage_table_name.to_sym).values(
          [ :external_id , :payload          , :foo_id , :external_foo_id ] ,
          [ 'existing'   , 'updated content' , 1       , 'ignored_column' ] ,
          [ 'deleted'    , 'updated content' , 2       , 'ignored_column' ] ,
        )

        subject.transition_reinstate

        expect(subject.stage_table_name.to_sym).to have_values(
          [ :external_id , :transition  ] ,
          [ 'existing'   , nil          ] ,
          [ 'deleted'    , 'REINSTATE'  ] ,
        )
      end
    end

  end
end
