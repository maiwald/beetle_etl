require 'spec_helper'

module BeetleETL
  describe Load do

    let(:external_source) { 'my_source' }

    let(:today) { Time.new(2020, 3, 24) }
    let(:yesterday) { Time.new(2020, 3, 23) }

    let(:config) do
      Configuration.new.tap do |c|
        c.external_source = external_source
        c.database = test_database
      end
    end

    subject { Load.new(config, :example_table, []) }

    before do
      allow(subject).to receive(:now) { today }

      test_database.create_schema(:stage)
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
        DateTime :created_at
        DateTime :updated_at
        DateTime :deleted_at

        String :payload, size: 255
        String :ignored_attribute, size: 255
        Integer :foo_id
      end
    end

    describe '#depenencies' do
      it 'depends on Transform of the same table and AssignIds of its dependees' do
        relations = {
          dependee_a_id: :dependee_a,
          dependee_b_id: :dependee_b,
        }

        expect(Load.new(config, :depender, relations).dependencies).to eql(
          [
            'dependee_a: Load',
            'dependee_b: Load',
          ].to_set
        )
      end
    end

    describe '#run' do
      it 'runs all load steps' do
        %w(create update delete).each do |transition|
          expect(subject).to receive(:"load_#{transition}")
        end

        subject.run
      end
    end

    describe '#load_create' do
      it 'loads records into the target table' do
        insert_into(subject.stage_table_name.to_sym).values(
          [ :id , :external_id  , :transition , :external_foo_id , :foo_id , :payload       ] ,
          [ 3   , 'external_id' , 'CREATE'    , 'foo_id'         , 22      , 'content'      ] ,
        )

        subject.load_create

        expect(:example_table).to have_values(
          [ :id , :external_id  , :external_source , :foo_id , :created_at , :updated_at , :deleted_at , :payload  ] ,
          [ 3   , 'external_id' , external_source  , 22      , today       , today       , nil         , 'content' ] ,
        )
      end
    end

    describe '#load_update' do
      it 'updates existing records' do
        insert_into(:example_table).values(
          [ :id , :external_id  , :external_source , :foo_id , :created_at , :updated_at , :deleted_at , :payload  ] ,
          [ 1   , 'external_id' , external_source  , 22      , yesterday   , yesterday   , nil         , 'content' ] ,
        )

        insert_into(subject.stage_table_name.to_sym).values(
          [ :id , :external_id  , :transition , :external_foo_id , :foo_id , :payload          ] ,
          [ 1   , 'external_id' , 'UPDATE'    , 'foo_id'         , 33      , 'updated content' ] ,
        )

        subject.load_update

        expect(:example_table).to have_values(
          [ :id , :external_id  , :external_source , :foo_id , :created_at , :updated_at , :deleted_at , :payload          ] ,
          [ 1   , 'external_id' , external_source  , 33      , yesterday   , today       , nil         , 'updated content' ] ,
        )
      end

      it 'restores deleted records' do
        insert_into(:example_table).values(
          [ :id , :external_id  , :external_source , :foo_id , :created_at , :updated_at , :deleted_at , :payload  ] ,
          [ 1   , 'external_id' , external_source  , 22      , yesterday   , yesterday   , nil         , 'content' ] ,
        )

        insert_into(subject.stage_table_name.to_sym).values(
          [ :id , :external_id  , :transition , :external_foo_id , :foo_id , :payload          ] ,
          [ 1   , 'external_id' , 'REINSTATE' , 'foo_id'         , 33      , 'updated content' ] ,
        )

        subject.load_update

        expect(:example_table).to have_values(
          [ :id , :external_id  , :external_source , :foo_id , :created_at , :updated_at , :deleted_at , :payload          ] ,
          [ 1   , 'external_id' , external_source  , 33      , yesterday   , today       , nil         , 'updated content' ] ,
        )
      end
    end

    describe '#load_delete' do
      it 'marks existing records as deleted' do
        insert_into(:example_table).values(
          [ :id , :external_id  , :external_source , :foo_id , :created_at , :updated_at , :deleted_at , :payload  ] ,
          [ 1   , 'external_id' , external_source  , 22      , yesterday   , yesterday   , nil         , 'content' ] ,
        )

        insert_into(subject.stage_table_name.to_sym).values(
          [ :id , :external_id  , :transition , :external_foo_id , :foo_id , :payload          ] ,
          [ 1   , 'external_id' , 'DELETE'    , 'foo_id'         , 33      , 'updated content' ] ,
        )

        subject.load_delete

        expect(:example_table).to have_values(
          [ :id , :external_id  , :external_source , :foo_id , :created_at , :updated_at , :deleted_at , :payload  ] ,
          [ 1   , 'external_id' , external_source  , 22      , yesterday   , today       , today       , 'content' ] ,
        )
      end
    end

  end
end
