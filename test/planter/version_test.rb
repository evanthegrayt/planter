require 'test_helper'

class Planter::VersionTest < ActiveSupport::TestCase
  test 'version exists and follows semantiv versioning' do
    assert Planter::VERSION
    assert_match Planter::Version.to_s, Planter::VERSION
  end

  test 'uest_to_a' do
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

  test 'to_h' do
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

  test 'to_s' do
    assert_instance_of(String, Planter::Version.to_s)
    assert_match(/\d+\.\d+.\d+/, Planter::Version.to_s)
  end

  test 'major' do
    assert_instance_of(Integer, Planter::Version::MAJOR)
  end

  test 'minor' do
    assert_instance_of(Integer, Planter::Version::MINOR)
  end

  test 'patch' do
    assert_instance_of(Integer, Planter::Version::PATCH)
  end

  test 'readme should contain the current version' do
    refute_empty File.readlines(
      File.join(__dir__, '..', '..', 'README.md')
    ).grep(
      /gem\s+'planter',\s+'(?:~>(?:\s)?)?#{Planter::VERSION}'/
    )
  end

  test 'Gemfile.lock should contain the current version' do
    refute_empty File.readlines(
      File.join(__dir__, '..', '..', 'Gemfile.lock')
    ).grep(
      /^\s*planter\s+\(#{Planter::VERSION}\)/
    )
  end
end
