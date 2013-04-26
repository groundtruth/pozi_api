require "pg"

module PoziAPI
  class Store

    def initialize(database, table)
      @table = table
      options = { dbname: database }
      options[:host] = ENV["POZI_API_PG_HOST"] if ENV["POZI_API_PG_HOST"]
      options[:port] = ENV["POZI_API_PG_PORT"] if ENV["POZI_API_PG_PORT"]
      @connection = PG.connect(options)
    end

    def create
    end

    def read
      result = @connection.exec("SELECT * FROM #{@table};")
      features = result.to_a.map do |row|
        # if row['the_geom_geojson']
        #   geometry = 
        #   row.delete("the_geom_geojson")
        # end
        # {
        #   "type" => "Feature",
        #   "properties"
        # }
      end
      {
        "type" => "FeatureCollection",
        "features" => features
      }.to_json
    end

    def update
    end

    def delete
    end

  end
end

