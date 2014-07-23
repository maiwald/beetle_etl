require 'spec_helper'

module Beetle
  describe TableDiff do

    let(:run_id) { 1 }
    let(:transformation) { double(:transformation, table_name: 'example_table') }
    subject { TableDiff.new(transformation) }

    before do
      test_database.create_schema(:stage)
      test_database.create_table(:stage__example_table) do
        Integer :import_run_id
        String :external_id, size: 255
        String :external_source, size: 255
        String :transition, size: 20
        index [:import_run_id, :external_id, :external_source]
      end

      test_database.create_table(:example_table) do
        String :external_id, size: 255
        String :external_source, size: 255
      end

      insert_into(:example_table).values(
        [ :external_id , :external_source ] ,
        [ 'existing'   , 'my_source'      ]
      )

      Beetle.configure do |config|
        config.stage_schema = 'stage'
        config.external_source = 'my_source'
        config.database = test_database
      end

      allow(Beetle).to receive(:state) { double(:state, run_id: run_id) }
    end

    describe '#transition_create' do
      it 'assigns the transition CREATE to new records' do
        insert_into(:stage__example_table).values(
          [ :import_run_id , :external_id , :external_source ],
          [ run_id         , 'created'    , 'my_source'      ]
        )

        subject.transition_create

        expect(:stage__example_table).to have_values(
          [ :import_run_id , :external_id , :external_source , :transition],
          [ run_id         , 'created'    , 'my_source'      , 'CREATE'  ]
        )

      end
    end

    context 'KEEP'
    context 'UNDELETE'
    context 'UPDATE'
    context 'DELETE'
    context 'KEEP_DELETED'
  end
end
