# BeetleETL
[![Build Status](https://travis-ci.org/maiwald/beetle_etl.svg?branch=master)](https://travis-ci.org/maiwald/beetle_etl)
[![Code Climate](https://codeclimate.com/github/maiwald/beetle_etl.png)](https://codeclimate.com/github/maiwald/beetle_etl)

BeetleETL helps you with synchronising relational databases and recurring imports of data. It is actually quite nice.

It currently only works with PostgreSQL databases.

## Installation

Add this line to your application's Gemfile:

    gem 'beetle_etl'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install beetle_etl

## Usage

### Configuration

    BeetleETL.configure do |config|
      config.transformation_file = # path to your imports
      config.database_config = # sequel database config
    # or config.database = # sequel database instance
      config.external_source = ‘source_name’
      config.logger = Logger.new(STDOUT)
    end

### Defining Imports

Fill a file with all the tables you wish to import and write queries to select the data you want.

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


### Running BeetleETL

    BeetleETL.import

## Development

To run the specs call

    $ bundle exec rspec

## Contributing

1. Fork it ( https://github.com/maiwald/beetle_etl/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
