desc "travis-ci.org build"
task :travis do
  system "sudo apt-get install postgis"
  ENV["RESTFUL_GEOF_PG_HOST"] = "127.0.0.1"
  ENV["RESTFUL_GEOF_PG_USERNAME"] = "postgres"

  system "rspec spec"
end

