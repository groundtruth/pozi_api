desc "travis-ci.org build"
task :travis do
  system "sudo apt-get install python-software-properties"
  system "sudo apt-add-repository --yes ppa:sharpie/for-science"
  system "sudo apt-add-repository --yes ppa:sharpie/postgis-stable"
  system "sudo apt-add-repository --yes ppa:ubuntugis/ubuntugis-unstable"
  system "sudo apt-get update"
  system "sudo apt-get install postgresql-9.1-postgis2"

  ENV["RESTFUL_GEOF_PG_HOST"] = "127.0.0.1"
  ENV["RESTFUL_GEOF_PG_USERNAME"] = "postgres"

  exec "rspec -f spec"
end

namespace :coverage do

  def define_task name, description, path
    desc description
    task name do
      puts "Checking #{description}..."
      require "simplecov"
      SimpleCov.start
      require_relative "spec/spec_helper"
      Dir.glob("lib/**/*.rb").each { |file| require_relative file }
      RSpec::Core::Runner.run([path])
      system "open coverage/index.html"
    end
  end

  define_task :unit, "unit spec coverage", "spec/restful_geof"
  define_task :integration, "integration spec coverage", "spec/integration"
  define_task :full, "full spec suite coverage", "spec"

end

