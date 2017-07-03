# BeetleETL
[![Build Status](https://travis-ci.org/maiwald/beetle_etl.svg?branch=master)](https://travis-ci.org/maiwald/beetle_etl)

BeetleETL helps you with synchronising relational databases and recurring imports of reference data. It is actually quite nice.

Consider you have a set of database tables representing third party data (i.e. the ```source```) and you want to synchronize a set of tables in your application (i.e. the ```target```) with that third party data. Further consider that you want to apply transformations to that ```source``` data before you import it.

You define your transformations and BeetleETL will to the rest. Even when your ```source``` data changes, when you run BeetleETL again, it can keep track of what changes need to be applied to what records in your application’s tables.

It currently only works with PostgreSQL databases.

## Installation

Add this line to your application's Gemfile:

    gem 'beetle_etl'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install beetle_etl

## Setup

Make sure the tables you want to import contain columns named ```external_id``` and ```external_source``` of type ```CHARACTER VARYING(255)```, as well as timestamp columns named ```created_at```, ```updated_at``` and, ```deleted_at```.

## Usage

### Configuration

Create a configuration object

```ruby
configuration = BeetleETL::Configuration.new do |config|
  # path to your transformation file
  config.transformation_file = "../my_fancy_transformations"

  # sequel database config
  config.database_config = {
    adapter: 'postgres'
    encoding: utf8
    host: my_host
    database: my_database
    username: 'foo'
    password: 'bar'
    pool: 5
    pool_timeout: 360
    connect_timeout: 360
  }
  # or config.database = # sequel database instance

  # name of your soruce
  config.external_source = "important_data"

  # target schema in case you use postgres schemas
  config.target_schema = "public" # default

  # logger
  config.logger = Logger.new(STDOUT) # default
end
```

### Defining Imports

Fill a ```transformation``` file with import directives like this:

```ruby
import :departments do
  columns :name

  references :organisations, on: :organisation_id

  query <<-SQL
    INSERT INTO #{stage_table} (
      external_id,
      name,
      external_organisation_id
    )

    SELECT
      o.id,
      o.”dep_name”,
      data.”address”

    FROM ”Organisation” o
    JOIN additional_data data
      ON data.org_id = o.id
  SQL
end
```

```import``` takes the name of the table you want to fill and the configuration as arguments.
With ```columns``` you define what columns BeetleETL is supposed to fill in your application’s table.
The ```query``` transforms the data. Make sure that you insert into ```#{stage_table}``` as the name of the actual table, that this inserts into will be filled in by BeetleETL during runtime.
Define any foreign references your table has to other tables using the ```refrecences(on:)``` directive. For every foreign key your table has, BeeteETL requires you to fill in a column named ```external_foreign_key``` (prepend "```external_```" to your actual foreign key column).


### Running BeetleETL

    BeetleETL.import(configuration)

## Development

To run the specs call

    $ bundle exec rspec

## Contributing

1. Fork it ( https://github.com/maiwald/beetle_etl/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
