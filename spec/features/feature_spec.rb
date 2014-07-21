require 'spec_helper'
require_relative 'example_schema'

describe Beetle do

  include ExampleSchema

  let!(:now) { Time.new(2014, 07, 17, 16, 12) }
  before { allow(Time).to receive(:now) { now } }

  before { create_tables }
  after { drop_tables }

  xit 'is a working', :feature do
    insert_into('source.Organisation').values(
      [ :pkOrgId , :Name   , :Abteilung ] ,
      [ 1        , 'Apple' , 'iPhone'   ] ,
      [ 2        , 'Apple' , 'MacBook'  ] ,
    )

    Beetle.import File.expand_path('../example_transform.rb', __FILE__)

    expect('public.organisations').to have_values(
      [ :id , :external_id , :external_source , :name   , :created_at , :deleted_at ] ,
      [ 1   , 'Apple'      , 'source_name'    , 'Apple' , now         , nil         ]
    )

    expect('public.departments').to have_values(
      [ :id , :external_id , :external_source , :name     , :organisation_id , :created_at , :deleted_at ] ,
      [ 1   , '[apple-1]'  , 'source_name'    , 'iPhone'  , 1                , now         , nil         ] ,
      [ 2   , '[apple-2]'  , 'source_name'    , 'MacBook' , 1                , now         , nil         ] ,
    )
  end

end
