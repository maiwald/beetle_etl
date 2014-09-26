require 'spec_helper'
require_relative 'example_schema'
require 'yaml'

require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/numeric/time'

describe BeetleETL do

  include ExampleSchema

  let!(:now) { Time.new(2014, 07, 17, 16, 12).beginning_of_day }
  before { allow(Time).to receive(:now) { now } }

  before { create_tables }
  after { drop_tables }

  it 'is a working', :feature do
    insert_into(:source__Organisation).values(
      [ :pkOrgId , :Name   , :Abteilung ] ,
      [ 1        , 'Apple' , 'iPhone'   ] ,
      [ 2        , 'Apple' , 'MacBook'  ] ,
    )

    BeetleETL.configure do |config|
      config.transformation_file = File.expand_path('../example_transform.rb', __FILE__)
      config.database = test_database
      config.external_source = 'source_name'
      config.stage_schema = 'stage'
    end


    BeetleETL.import


    expect(:organisations).to have_values(
      [ :id , :external_id , :external_source , :name   , :created_at , :updated_at , :deleted_at ] ,
      [ 1   , 'Apple'      , 'source_name'    , 'Apple' , now         , now         , nil         ]
    )

    expect(:departments).to have_values(
      [ :id , :external_id , :external_source , :name     , :organisation_id , :created_at , :updated_at , :deleted_at ] ,
      [ 1   , '[Apple,1]'  , 'source_name'    , 'iPhone'  , 1                , now         , now         , nil         ] ,
      [ 2   , '[Apple,2]'  , 'source_name'    , 'MacBook' , 1                , now         , now         , nil         ] ,
    )
  end

end
