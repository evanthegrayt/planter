require "test_helper"

class Planter::VersionTest < ActiveSupport::TestCase
  test "version exists and follows semantiv versioning" do
    assert Planter::VERSION
    assert_match /\d+\.\d+.\d+/, Planter::VERSION
  end
end
