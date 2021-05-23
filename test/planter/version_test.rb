require "test_helper"

class Planter::VersionTest < ActiveSupport::TestCase
  test "version exists and follows semantiv versioning" do
    assert Planter::VERSION
    assert_match Planter::Version.to_s, Planter::VERSION
  end

  def test_to_a
    assert_instance_of(Array, Planter::Version.to_a)
    assert_equal(
      [
        Planter::Version::MAJOR,
        Planter::Version::MINOR,
        Planter::Version::PATCH
      ],
      Planter::Version.to_a
    )
  end

  def test_to_h
    assert_instance_of(Hash, Planter::Version.to_h)
    assert_equal(
      {
        major: Planter::Version::MAJOR,
        minor: Planter::Version::MINOR,
        patch: Planter::Version::PATCH
      },
      Planter::Version.to_h
    )
  end

  def test_to_s
    assert_instance_of(String, Planter::Version.to_s)
    assert_match(/\d+\.\d+.\d+/, Planter::Version.to_s)
  end

  def test_major
    assert_instance_of(Integer, Planter::Version::MAJOR)
  end

  def test_minor
    assert_instance_of(Integer, Planter::Version::MINOR)
  end

  def test_patch
    assert_instance_of(Integer, Planter::Version::PATCH)
  end
end
