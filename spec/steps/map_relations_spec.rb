require 'spec_helper'

module BeetleETL
  describe MapRelations do

    let(:config) do
      OpenStruct.new({
        external_source: 'my_source',
        target_schema: 'public',
        database: test_database
      })
    end

    let(:dependee_a) do
      BeetleETL::Naming.stage_table_name('my_source', :dependee_a).to_sym
    end
    let(:dependee_b) do
      BeetleETL::Naming.stage_table_name('my_source', :dependee_b).to_sym
    end

    let(:relations) do
      {
        dependee_a_id: :dependee_a,
        dependee_b_id: :dependee_b,
      }
    end

    subject do
      MapRelations.new(config, :depender, relations)
    end

    before do
      test_database.create_table(dependee_a) do
        Integer :id
        String :external_id, size: 255
      end

      test_database.create_table(dependee_b) do
        Integer :id
        String :external_id, size: 255
      end

      test_database.create_table(subject.stage_table_name.to_sym) do
        String :external_id, size: 255

        String :external_dependee_a_id
        Integer :dependee_a_id

        String :external_dependee_b_id
        Integer :dependee_b_id
      end
    end

    describe '#depenencies' do
      it 'depends on Transform of the same table and TableDiff of its dependees' do
        expect(subject.dependencies).to eql(
          [
            'dependee_a: TableDiff',
            'dependee_b: TableDiff',
            'depender: Transform',
          ].to_set
        )
      end
    end

    describe '#run' do
      it 'maps external foreign key references to id references ' do
        insert_into(dependee_a).values(
          [ :id , :external_id ] ,
          [ 1   , 'a_id'       ] ,
          [ 2   , 'a_id'       ] ,
        )

        insert_into(dependee_b).values(
          [ :id , :external_id ] ,
          [ 26  , 'b_id'       ] ,
        )

        insert_into(Sequel.qualify("public", subject.stage_table_name)).values(
          [ :external_dependee_a_id , :external_dependee_b_id ] ,
          [ 'a_id'                  , 'b_id'                  ] ,
        )

        subject.run

        expect(Sequel.qualify("public", subject.stage_table_name)).to have_values(
          [ :dependee_a_id , :dependee_b_id ] ,
          [ 1              , 26             ] ,
        )
      end
    end

  end
end
