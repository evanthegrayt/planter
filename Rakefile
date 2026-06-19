require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"
require "rdoc/task"
require "standard/rake"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.verbose = false
end

RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
  rdoc.rdoc_dir = "docs"
  rdoc.rdoc_files.include("README.md", "lib/**/*.rb")
end

task default: :test

namespace :version do
  desc "Print the current version from the version.rb file"
  task :current do
    puts Planter::VERSION
  end

  namespace :increment do
    desc "Increment the version's PATCH level"
    task :patch do
      File.join(__dir__, "lib", "planter", "version.rb").then do |version_file|
        File.write(
          version_file,
          File.read(version_file).sub(/(PATCH\s=\s)(\d+)/) { "#{$1}#{$2.next}" }
        )
      end
      system("bundle lock")
    end
    desc "Increment the version's MINOR level"
    task :minor do
      File.join(__dir__, "lib", "planter", "version.rb").then do |version_file|
        File.write(
          version_file,
          File.read(version_file)
            .sub(/(PATCH\s=\s)(\d+)/) { "#{$1}0" }
            .sub(/(MINOR\s=\s)(\d+)/) { "#{$1}#{$2.next}" }
        )
      end
      system("bundle lock")
    end
    desc "Increment the version's MAJOR level"
    task :major do
      File.join(__dir__, "lib", "planter", "version.rb").then do |version_file|
        File.write(
          version_file,
          File.read(version_file)
            .sub(/(PATCH\s=\s)(\d+)/) { "#{$1}0" }
            .sub(/(MINOR\s=\s)(\d+)/) { "#{$1}0" }
            .sub(/(MAJOR\s=\s)(\d+)/) { "#{$1}#{$2.next}" }
        )
      end
      system("bundle lock")
    end
  end
end
