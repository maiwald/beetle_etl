require 'spec_helper'
require 'yaml'

module BeetleETL
  describe Configuration do

    subject { Configuration.new }

    let(:database_config) do
      config_path = File.expand_path('../support/database.yml', __FILE__)
      YAML.load(File.read(config_path))
    end

    describe "#database" do
     it "builds a SequelAdapter when passed a Sequel::Database" do
        subject.database = test_database

        expect { subject.database.execute("SELECT 1") }.not_to raise_error
      end

      it "builds a SequelAdapter from config when no database is passed" do
        subject.database_config = database_config

        expect { subject.database.execute("SELECT 1") }.not_to raise_error
      end

      it "raises an error if no database or database_config is passed" do
        expect { subject.database }
          .to raise_error(BeetleETL::InvalidConfigurationError)
      end
    end

    describe "#disconnect_database" do
      it "disconnects from database if database_config was passed" do
        subject.database_config = database_config

        expect(subject.database).to receive(:disconnect)

        subject.disconnect_database
      end

      it "does not disconnect from database if database object was passed" do
        subject.database = test_database

        expect(subject.database).not_to receive(:disconnect)

        subject.disconnect_database
      end
    end

    describe "#target_schema" do
      it "returns 'public' by default" do
        expect(subject.target_schema).to eql("public")
      end

      it "returns target_schema if target_schema is not 'public'" do
        subject.target_schema = "foo"
        expect(subject.target_schema).to eql("foo")
      end
    end
  end
end
