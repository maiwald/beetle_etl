require 'spec_helper'

require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/numeric/time'

module BeetleETL
  describe State do
    subject { State.new }

    before do
      BeetleETL.configure do |config|
        config.stage_schema = 'stage'
        config.database = test_database
      end

      test_database.create_schema 'stage'
      test_database.create_table :stage__import_runs do
        primary_key :id
        String :state, size: 10, null: false
        DateTime :started_at, null: false
        DateTime :finished_at
      end
    end

    describe '#start_import' do
      let(:now) { 1.minute.ago.beginning_of_day }

      it 'registers a new import in the import_runs table' do
        allow(subject).to receive(:now) { now }

        subject.start_import

        expect(:stage__import_runs).to have_values(
          [ :id , :state    , :started_at , :finished_at ] ,
          [ 1   , 'RUNNING' , now         , nil          ]
        )
      end

      it 'raises an exception if there is alreay an import marked as running' do
        insert_into(:stage__import_runs).values(
          [ :id , :state    , :started_at , :finished_at ] ,
          [ 1   , 'RUNNING' , now         , nil          ]
        )

        expect { subject.start_import }.to raise_exception(BeetleETL::ImportAleadyRunning)
      end
    end

    context 'run ids' do
      before do
        insert_into(:stage__import_runs).values(
          [ :state      , :started_at , :finished_at ] ,
          [ 'FAILED'    , 8.days.ago  , 7.days.ago   ] ,
          [ 'SUCCEEDED' , 6.days.ago  , 5.day.ago    ] ,
          [ 'SUCCEEDED' , 4.days.ago  , 3.days.ago   ] ,
          [ 'FAILED'    , 2.days.ago  , 1.day.ago    ] ,
        )
      end

      describe '#run_id' do
        it 'returns the import‘s id after it has been started' do
          subject.start_import
          expect(subject.run_id).to eql(5)
        end

        it 'raises an exception when the import has not been started' do
          expect { subject.run_id }.to raise_exception(BeetleETL::ImportNotRunning)
        end
      end

      describe '#last_run_id' do
        it 'returns nil if there is no last successful import' do
          test_database[:stage__import_runs].update(state: 'FAILED')

          subject.start_import
          expect(subject.last_run_id).to be_nil
        end

        it 'returns the id of the last successul import' do
          subject.start_import
          expect(subject.last_run_id).to eql(3)
        end
      end
    end

    context 'marking imports' do
      let(:now) { 1.minute.ago.beginning_of_day }
      let(:one_day_ago) { 1.day.ago.beginning_of_day }

      before do
        insert_into(:stage__import_runs).values(
          [ :state      , :started_at , :finished_at ] ,
          [ 'SUCCEEDED' , 2.days.ago  , one_day_ago  ] ,
        )
        allow(subject).to receive(:now) { now }
        subject.start_import
      end

      describe '#mark_as_failed' do
        it 'marks the current import as FAILED' do
          subject.mark_as_failed

          expect(:stage__import_runs).to have_values(
            [ :id , :state      , :finished_at ] ,
            [ 1   , 'SUCCEEDED' , one_day_ago  ] ,
            [ 2   , 'FAILED'    , now          ] ,
          )
        end
      end

      describe '#mark_as_succeeded' do
        it 'marks the current import as SUCCEEDED' do
          subject.mark_as_succeeded

          expect(:stage__import_runs).to have_values(
            [ :id , :state      , :finished_at ] ,
            [ 1   , 'SUCCEEDED' , one_day_ago  ] ,
            [ 2   , 'SUCCEEDED' , now          ] ,
          )
        end
      end
    end
  end
end
