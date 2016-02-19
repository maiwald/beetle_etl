require 'spec_helper'

module BeetleETL
  describe Configuration do

    subject { Configuration.new }

    describe "#database" do
      let(:database) { double(:database) }

      it "returns the object if present" do
        subject.database = database

        expect(subject.database).to eql(database)
      end

      it "builds a Sequel Database from config when no database is passed" do
        database_config = double(:database_config)
        subject.database_config = database_config

        expect(Sequel).to receive(:connect).with(database_config).once { database }

        expect(subject.database).to eql(database)
        expect(subject.database).to eql(database)
      end

      it "raises an error if no database or database_config is passed" do
        expect { subject.database }
          .to raise_error(BeetleETL::InvalidConfigurationError)
      end
    end

    describe "#disconnect_database" do
      let(:database) { double(:database) }

      it "disconnects from database if database_config was passed" do
        database_config = double(:database_config)

        expect(Sequel).to receive(:connect).with(database_config) { database }
        expect(database).to receive(:disconnect)

        subject.database_config = database_config
        subject.disconnect_database
      end

      it "does not disconnect from database if database object was passed" do
        expect(database).not_to receive(:disconnect)

        subject.database = database
        subject.disconnect_database
      end
    end

    describe "#target_schema" do
      it "returns nil if target_schema is 'public'" do
        subject.target_schema = "public"
        expect(subject.target_schema).to be_nil
      end

      it "returns target_schema if target_schema is not 'public'" do
        subject.target_schema = "foo"
        expect(subject.target_schema).to eql("foo")
      end
    end
  end
end
