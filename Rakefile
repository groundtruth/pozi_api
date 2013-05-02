desc "travis-ci.org build"
task :travis do
  system "sudo apt-get install python-software-properties"
  system "sudo apt-add-repository ppa:sharpie/for-science"
  system "sudo apt-add-repository ppa:sharpie/postgis-stable"
  system "sudo apt-add-repository ppa:ubuntugis/ubuntugis-unstable"
  system "sudo apt-get update"
  system "sudo apt-get install postgresql-9.1-postgis2"

  ENV["RESTFUL_GEOF_PG_HOST"] = "127.0.0.1"
  ENV["RESTFUL_GEOF_PG_USERNAME"] = "postgres"

  exec "rspec spec"
end

