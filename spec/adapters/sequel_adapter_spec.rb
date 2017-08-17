require "spec_helper"
require_relative "shared_examples"

module BeetleETL
  describe SequelAdapter do
    it_behaves_like "database adapter" do
      let(:adapter) { SequelAdapter.new(test_database) }
    end
  end
end
