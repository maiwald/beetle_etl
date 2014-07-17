require 'spec_helper'
require_relative 'example_schema'

describe Beetle do

  include ExampleSchema

  around :each do |example|
    create_tables
    example.run
    drop_tables
  end

  it 'imports stuff the way you want to', :feature do
    Beetle.import File.expand_path('example_transform.rb', __FILE__)
  end

end

