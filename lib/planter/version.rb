# frozen_string_literal: true

module Planter
  ##
  # Module that contains all gem version information. Follows semantic
  # versioning. Read: https://semver.org/
  module Version
    ##
    # Major version.
    #
    # @return [Integer]
    MAJOR = 0

    ##
    # Minor version.
    #
    # @return [Integer]
    MINOR = 2

    ##
    # Patch version.
    #
    # @return [Integer]
    PATCH = 0

    module_function

    ##
    # Version as +[MAJOR, MINOR, PATCH]+
    #
    # @return [Array]
    def to_a
      [MAJOR, MINOR, PATCH]
    end

    ##
    # Version as +MAJOR.MINOR.PATCH+
    #
    # @return [String]
    def to_s
      to_a.join('.')
    end

    ##
    # Version as +{major: MAJOR, minor: MINOR, patch: PATCH}+
    #
    # @return [Hash]
    def to_h
      Hash[%i[major minor patch].zip(to_a)]
    end
  end

  ##
  # Gem version, semantic.
  VERSION = Version.to_s.freeze
end
