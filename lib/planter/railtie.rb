# frozen_string_literal: true

module Planter
  class Railtie < ::Rails::Railtie # :nodoc:
    rake_tasks do
      load File.join(
        __dir__,
        "..",
        "tasks",
        "planter_tasks.rake"
      )
    end
  end
end
