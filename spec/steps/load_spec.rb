require 'spec_helper'

require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/numeric/time'

module BeetleETL
  describe Load do

    let(:run_id) { 1 }
    let(:old_run_id) { 5000 }
    let(:external_source) { 'my_source' }

    let(:now) { Time.now.beginning_of_day }
    let(:yesterday) { 1.day.ago.beginning_of_day }

    subject { Load.new(:example_table) }

    before do
      BeetleETL.configure do |config|
        config.stage_schema = 'stage'
        config.external_source = external_source
        config.database = test_database
      end

      allow(BeetleETL).to receive(:state) { double(:state, run_id: run_id) }
      allow(subject).to receive(:now) { now }

      test_database.create_schema(:stage)
      test_database.create_table(:stage__example_table) do
        Integer :import_run_id
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
        DateTime :created_at
        DateTime :updated_at
        DateTime :deleted_at

        String :payload, size: 255
        String :ignored_attribute, size: 255
        Integer :foo_id
      end
    end

    describe '#run' do
      it 'runs all load steps' do
        %w(create update delete undelete).each do |transition|
          expect(subject).to receive(:"load_#{transition}")
        end

        subject.run
      end
    end

    describe '#load_create' do
      it 'loads records into the public table' do
        insert_into(:stage__example_table).values(
          [ :id , :import_run_id , :external_id  , :transition , :external_foo_id , :foo_id , :payload       ] ,
          [ 3   , old_run_id     , 'external_id' , 'CREATE'    , 'foo_id'         , 999     , 'some content' ] ,
          [ 3   , run_id         , 'external_id' , 'CREATE'    , 'foo_id'         , 22      , 'content'      ] ,
        )

        subject.load_create

        expect(:example_table).to have_values(
          [ :id , :external_id  , :external_source , :foo_id , :created_at , :updated_at , :deleted_at , :payload  ] ,
          [ 3   , 'external_id' , external_source  , 22      , now         , now         , nil         , 'content' ] ,
        )
      end
    end

    describe '#load_update' do
      it 'updates existing records' do
        insert_into(:example_table).values(
          [ :id , :external_id  , :external_source , :foo_id , :created_at , :updated_at , :deleted_at , :payload  ] ,
          [ 1   , 'external_id' , external_source  , 22      , yesterday   , yesterday   , nil         , 'content' ] ,
        )

        insert_into(:stage__example_table).values(
          [ :id , :import_run_id , :external_id  , :transition , :external_foo_id , :foo_id , :payload          ] ,
          [ 1   , old_run_id     , 'external_id' , 'UPDATE'    , 'foo_id'         , 999     , 'some content'    ] ,
          [ 1   , run_id         , 'external_id' , 'UPDATE'    , 'foo_id'         , 33      , 'updated content' ] ,
        )

        subject.load_update

        expect(:example_table).to have_values(
          [ :id , :external_id  , :external_source , :foo_id , :created_at , :updated_at , :deleted_at , :payload          ] ,
          [ 1   , 'external_id' , external_source  , 33      , yesterday   , now         , nil         , 'updated content' ] ,
        )
      end
    end

    describe '#load_delete' do
      it 'marks existing records as deleted' do
        insert_into(:example_table).values(
          [ :id , :external_id  , :external_source , :foo_id , :created_at , :updated_at , :deleted_at , :payload  ] ,
          [ 1   , 'external_id' , external_source  , 22      , yesterday   , yesterday   , nil         , 'content' ] ,
        )

        insert_into(:stage__example_table).values(
          [ :id , :import_run_id , :external_id  , :transition , :external_foo_id , :foo_id , :payload          ] ,
          [ 1   , old_run_id     , 'external_id' , 'UPDATE'    , 'foo_id'         , 999     , 'some content'    ] ,
          [ 1   , run_id         , 'external_id' , 'DELETE'    , 'foo_id'         , 33      , 'updated content' ] ,
        )

        subject.load_delete

        expect(:example_table).to have_values(
          [ :id , :external_id  , :external_source , :foo_id , :created_at , :updated_at , :deleted_at , :payload  ] ,
          [ 1   , 'external_id' , external_source  , 22      , yesterday   , now         , now         , 'content' ] ,
        )
      end
    end

    describe '#load_undelete' do
      it 'reinstates deleted records' do
        insert_into(:example_table).values(
          [ :id , :external_id  , :external_source , :foo_id , :created_at , :updated_at , :deleted_at , :payload  ] ,
          [ 1   , 'external_id' , external_source  , 22      , yesterday   , yesterday   , nil         , 'content' ] ,
        )

        insert_into(:stage__example_table).values(
          [ :id , :import_run_id , :external_id  , :transition , :external_foo_id , :foo_id , :payload          ] ,
          [ 1   , old_run_id     , 'external_id' , 'UPDATE'    , 'foo_id'         , 999     , 'some content'    ] ,
          [ 1   , run_id         , 'external_id' , 'UNDELETE'  , 'foo_id'         , 33      , 'updated content' ] ,
        )

        subject.load_undelete

        expect(:example_table).to have_values(
          [ :id , :external_id  , :external_source , :foo_id , :created_at , :updated_at , :deleted_at , :payload          ] ,
          [ 1   , 'external_id' , external_source  , 33      , yesterday   , now         , nil         , 'updated content' ] ,
        )
      end
    end
  end
end
