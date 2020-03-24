require 'spec_helper'
require 'timecop'

require_relative 'example_schema'
require 'yaml'

Thread::abort_on_exception = true

describe BeetleETL do

  include ExampleSchema

  let!(:time1) { Time.new(2014 ,  7 , 17 , 16 , 12) }
  let!(:time2) { Time.new(2015 ,  2 ,  8 , 22 , 18) }
  let!(:time3) { Time.new(2015 , 11 ,  3 , 12 , 17) }

  before :each do
    create_tables

    database_config_path = File.expand_path('../support/database.yml', File.dirname(__FILE__))
    database_config = YAML.load(File.read(database_config_path))

    @config = BeetleETL::Configuration.new.tap do |c|
      c.transformation_file = File.expand_path('../example_transform.rb', __FILE__)
      c.database_config = database_config
      c.external_source = 'source_name'
      c.target_schema = 'my_target'
      c.logger = Logger.new(Tempfile.new("log"))
    end
  end

  after do
    drop_tables
  end

  it 'performs all possible transitions', :feature do
    # create, keep, update, delete, reinstate

    import1
    import2
    import3
  end

  def import1
    # create
    insert_into(Sequel.qualify("source", "Organisation")).values(
      [ :pkOrgId , :Name    , :Adresse        , :Abteilung ] ,
      [ 1        , 'Apple'  , 'Apple Street'  , 'iPhone'   ] ,
      [ 2        , 'Apple'  , 'Apple Street'  , 'MacBook'  ] ,
      [ 3        , 'Google' , 'Google Street' , 'Gmail'    ] ,
      [ 4        , 'Audi'   , 'Audi Street'   , 'A4'       ] ,
    )

    Timecop.freeze(time1) do
      BeetleETL.import(@config)
    end

    expect(Sequel.qualify("my_target", "organisations")).to have_values(
      [ :id                       , :external_id , :external_source , :name    , :address        , :created_at , :updated_at , :deleted_at ] ,
      [ organisation_id('Apple')  , 'Apple'      , 'source_name'    , 'Apple'  , 'Apple Street'  , time1       , time1       , nil         ] ,
      [ organisation_id('Google') , 'Google'     , 'source_name'    , 'Google' , 'Google Street' , time1       , time1       , nil         ] ,
      [ organisation_id('Audi')   , 'Audi'       , 'source_name'    , 'Audi'   , 'Audi Street'   , time1       , time1       , nil         ]
    )

    expect(Sequel.qualify("my_target", "departments")).to have_values(
      [ :id                         , :external_id , :organisation_id          , :external_source , :name     , :created_at , :updated_at , :deleted_at ] ,
      [ department_id('[Apple,1]')  , '[Apple,1]'  , organisation_id('Apple')  , 'source_name'    , 'iPhone'  , time1       , time1       , nil         ] ,
      [ department_id('[Apple,2]')  , '[Apple,2]'  , organisation_id('Apple')  , 'source_name'    , 'MacBook' , time1       , time1       , nil         ] ,
      [ department_id('[Google,3]') , '[Google,3]' , organisation_id('Google') , 'source_name'    , 'Gmail'   , time1       , time1       , nil         ] ,
      [ department_id('[Audi,4]')   , '[Audi,4]'   , organisation_id('Audi')   , 'source_name'    , 'A4'      , time1       , time1       , nil         ] ,
    )

    test_database[Sequel.qualify("source", "Organisation")].truncate
  end

  def import2
    # keep, update, delete
    insert_into(Sequel.qualify("source", "Organisation")).values(
      [ :pkOrgId , :Name    , :Adresse            , :Abteilung ] ,
      [ 1        , 'Apple'  , 'Apple Street'      , 'iPhone'   ] ,
      [ 2        , 'Apple'  , 'Apple Street'      , 'MacBook'  ] ,
      [ 3        , 'Google' , 'NEW Google Street' , 'Google+'  ] ,
    # [ 4        , 'Audi'   , 'Audi Street'       , 'A4'       ] ,
    )

    Timecop.freeze(time2) do
      BeetleETL.import(@config)
    end

    expect(Sequel.qualify("my_target", "organisations")).to have_values(
      [ :id                       , :external_id , :external_source , :name    , :address            , :created_at , :updated_at , :deleted_at ] ,
      [ organisation_id('Apple')  , 'Apple'      , 'source_name'    , 'Apple'  , 'Apple Street'      , time1       , time1       , nil         ] ,
      [ organisation_id('Google') , 'Google'     , 'source_name'    , 'Google' , 'NEW Google Street' , time1       , time2       , nil         ] ,
      [ organisation_id('Audi')   , 'Audi'       , 'source_name'    , 'Audi'   , 'Audi Street'       , time1       , time2       , time2       ]
    )

    expect(Sequel.qualify("my_target", "departments")).to have_values(
      [ :id                         , :external_id , :organisation_id          , :external_source , :name     , :created_at , :updated_at , :deleted_at ] ,
      [ department_id('[Apple,1]')  , '[Apple,1]'  , organisation_id('Apple')  , 'source_name'    , 'iPhone'  , time1       , time1       , nil         ] ,
      [ department_id('[Apple,2]')  , '[Apple,2]'  , organisation_id('Apple')  , 'source_name'    , 'MacBook' , time1       , time1       , nil         ] ,
      [ department_id('[Google,3]') , '[Google,3]' , organisation_id('Google') , 'source_name'    , 'Google+' , time1       , time2       , nil         ] ,
      [ department_id('[Audi,4]')   , '[Audi,4]'   , organisation_id('Audi')   , 'source_name'    , 'A4'      , time1       , time2       , time2       ] ,
    )

    test_database[Sequel.qualify("source", "Organisation")].truncate
  end

  def import3
    # reinstate with update
    insert_into(Sequel.qualify("source", "Organisation")).values(
      [ :pkOrgId , :Name    , :Adresse            , :Abteilung ] ,
      [ 1        , 'Apple'  , 'Apple Street'      , 'iPhone'   ] ,
      [ 2        , 'Apple'  , 'Apple Street'      , 'MacBook'  ] ,
      [ 3        , 'Google' , 'NEW Google Street' , 'Google+'  ] ,
      [ 4        , 'Audi'   , 'NEW Audi Street'   , 'A4'       ] ,
    )

    Timecop.freeze(time3) do
      BeetleETL.import(@config)
    end

    expect(Sequel.qualify("my_target", "organisations")).to have_values(
      [ :id                       , :external_id , :external_source , :name    , :address            , :created_at , :updated_at , :deleted_at ] ,
      [ organisation_id('Apple')  , 'Apple'      , 'source_name'    , 'Apple'  , 'Apple Street'      , time1       , time1       , nil         ] ,
      [ organisation_id('Google') , 'Google'     , 'source_name'    , 'Google' , 'NEW Google Street' , time1       , time2       , nil         ] ,
      [ organisation_id('Audi')   , 'Audi'       , 'source_name'    , 'Audi'   , 'NEW Audi Street'   , time1       , time3       , nil         ]
    )

    expect(Sequel.qualify("my_target", "departments")).to have_values(
      [ :id                         , :external_id , :organisation_id          , :external_source , :name     , :created_at , :updated_at , :deleted_at ] ,
      [ department_id('[Apple,1]')  , '[Apple,1]'  , organisation_id('Apple')  , 'source_name'    , 'iPhone'  , time1       , time1       , nil         ] ,
      [ department_id('[Apple,2]')  , '[Apple,2]'  , organisation_id('Apple')  , 'source_name'    , 'MacBook' , time1       , time1       , nil         ] ,
      [ department_id('[Google,3]') , '[Google,3]' , organisation_id('Google') , 'source_name'    , 'Google+' , time1       , time2       , nil         ] ,
      [ department_id('[Audi,4]')   , '[Audi,4]'   , organisation_id('Audi')   , 'source_name'    , 'A4'      , time1       , time3       , nil         ] ,
    )

    test_database[Sequel.qualify("source", "Organisation")].truncate
  end

  def organisation_id(external_id)
    test_database[Sequel.qualify("my_target", "organisations")].first(external_id: external_id)[:id]
  end

  def department_id(external_id)
    test_database[Sequel.qualify("my_target", "departments")].first(external_id: external_id)[:id]
  end

end
