require "pg"
require "pg_typecast"
require "json"

require "restful_geof/table_info"
require "restful_geof/query"

module RestfulGeof

  class Model

    def initialize(database, table_name)
      options = { dbname: database }
      options[:host] = ENV["RESTFUL_GEOF_PG_HOST"] || "localhost"
      options[:port] = ENV["RESTFUL_GEOF_PG_PORT"] || "5432"
      options[:user] = ENV["RESTFUL_GEOF_PG_USERNAME"] if ENV["RESTFUL_GEOF_PG_USERNAME"]
      options[:password] = ENV["RESTFUL_GEOF_PG_PASSWORD"] if ENV["RESTFUL_GEOF_PG_PASSWORD"]
      @connection = PG.connect(options)

      @table_name = table_name

      @table_info = TableInfo.new(
        @connection.exec(
          Query.new.
            select("column_name", "udt_name").
            from("information_schema.columns").
            where("table_catalog = '#{ esc_s @connection.db }'").
            and("table_name = '#{ esc_s @table_name }'").to_sql
        ).to_a
      )
    end


    def create
    end

    def read
    end

    def find(conditions={})
      conditions[:is] ||= {}
      conditions[:contains] ||= {}
      conditions[:matches] ||= {}

      query = Query.new

      query.select(@table_info.normal_columns)
      query.select("ST_AsGeoJSON(ST_Transform(#{@table_info.geometry_column}, 4326), 15, 2) AS geometry_geojson") if @table_info.geometry_column

      query.from(esc_i @table_name)

      conditions[:is].each do |field, value|
        value_expression = @table_info.integer_col?(field) ? Integer(value).to_s : "'#{ esc_s value }'"
        query.where "#{ esc_i field } = #{ value_expression }"
      end

      conditions[:contains].each do |field, value|
        query.where "#{ esc_i field }::varchar ILIKE '%#{ esc_s value.gsub(/(?=[%_])/, "\\") }%'"
        query.order_by "position(upper('#{ esc_s value }') in upper(#{ esc_i field }::varchar))"
      end

      conditions[:matches].each do |field, value|
        query.where <<-END_CONDITION
          #{ esc_i field } @@
          CASE
            WHEN char_length(plainto_tsquery('#{ esc_s value }')::varchar) > 0
            THEN to_tsquery(plainto_tsquery('#{ esc_s value }')::varchar || ':*')
            ELSE plainto_tsquery('#{ esc_s value }')
          END
        END_CONDITION
      end

      query.limit conditions[:limit]

      as_feature_collection(@connection.exec(query.to_sql).to_a)
    end

    def update
    end

    def delete
    end

    private

    def esc_i identifier
      @connection.escape_identifier(identifier)
    end

    def esc_s string
      @connection.escape_string(string)
    end

    def as_feature_collection(results)
      {
        "type" => "FeatureCollection",
        "features" => results.to_a.map do |row|
          {
            "type" => "Feature",
            "properties" => row.select { |k,v| k != :geometry_geojson }
          }.merge(
            begin
              if row[:geometry_geojson].to_s.empty?
                {}
              else
                { "geometry" => JSON.parse(row[:geometry_geojson]) }
              end
            end
          )
        end
      }.to_json
    end

  end
end

