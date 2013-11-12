require "rack/test"
require "rspec"

require "restful_geof/root_path"


def clean_db
  %x{psql -f #{RestfulGeof::ROOT_PATH}/spec/resources/seeds.sql -U #{ENV["RESTFUL_GEOF_PG_USERNAME"] || ENV["USER"]}}
end
