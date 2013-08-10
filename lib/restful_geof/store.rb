require "ostruct"
require "pg"
require "pg_typecast"
require "json"

require "rgeo"
require "rgeo/geo_json"

require "restful_geof/table_info"
require "restful_geof/sql/query"
require "restful_geof/sql/insert"
require "restful_geof/sql/update"

module RestfulGeof

  class Store

    class Outcome
      def self.good(info={})
        OpenStruct.new({ okay?: true, data: {} }.merge(info))
      end
      def self.bad(info={})
        OpenStruct.new({ okay?: false, problem: "Unknown" }.merge(info))
      end
    end

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
          SQL::Query.new.
            select("column_name", "udt_name").
            from("information_schema.columns").
            where("table_catalog = '#{ esc_s @connection.db }'").
            and("table_name = '#{ esc_s @table_name }'").to_sql
        ).to_a
      )

      if block_given?
        yield self
        @connection.close
      end
    end

    def create(params)
      feature = RGeo::GeoJSON.decode(params[:body_json], :json_parser => :json)
      properties = Hash[feature.properties.map { |k,v| [esc_i(k), i_or_quoted_s_for(v, k)] }]

      insert = with_normal_and_geo_selects(SQL::Insert.new).into(esc_i(@table_name)).
        fields(properties.keys + [esc_i(@table_info.geometry_column)]).
        values(properties.values + ["ST_GeomFromText('#{ feature.geometry.as_text }', 4326)"])

      # TODO: add checking of cmd_status here
      results = @connection.exec(insert.to_sql).to_a
      Outcome.good(data: as_feature(results.first))
    end

    def update(params)
      feature = RGeo::GeoJSON.decode(params[:body_json], :json_parser => :json)
      properties = Hash[feature.properties.map { |k,v| [esc_i(k), i_or_quoted_s_for(v, k)] }]

      unless feature.properties[@table_info.id_column].to_s == params[:id].to_s
        return Outcome.bad(problem: "ID in payload doesn't match ID in URL")
      end

      update = with_normal_and_geo_selects(SQL::Update.new.table(esc_i(@table_name))).
        fields(properties.keys + [esc_i(@table_info.geometry_column)]).
        values(properties.values + ["ST_GeomFromText('#{ feature.geometry.as_text }', 4326)"]).
        where("#{ esc_i @table_info.id_column } = #{ i_or_quoted_s_for(params[:id], @table_info.id_column) }")

      result = @connection.exec(update.to_sql)
      rows = result.to_a
      if result.cmd_status == "UPDATE 1" && rows.count == 1
        Outcome.good(data: as_feature(rows.first))
      else
        Outcome.bad
      end
    end

    def read(params)
      query = with_normal_and_geo_selects(SQL::Query.new).
        where("#{ esc_i @table_info.id_column } = #{ i_or_quoted_s_for(params[:id], @table_info.id_column) }").
        from(esc_i @table_name)
      results = @connection.exec(query.to_sql).to_a
      if results.count == 1
        Outcome.good(data: as_feature(results.first))
      else
        Outcome.bad(problem: "Not found")
      end
    end

    def delete(params)
      query_sql = <<-END_SQL
        DELETE FROM #{ esc_i @table_name }
        WHERE #{ esc_i @table_info.id_column } = #{ i_or_quoted_s_for(params[:id], @table_info.id_column) };
      END_SQL
      if @connection.exec(query_sql).cmd_status == "DELETE 1"
        Outcome.good
      else
        Outcome.bad
      end
    end

    def find(params={ :conditions => {} })
      # TODO: clarify naming of conditions, options, query.
 
      params[:conditions][:is] ||= {}
      params[:conditions][:in] ||= {}
      params[:conditions][:contains] ||= {}
      params[:conditions][:matches] ||= {}

      query = with_normal_and_geo_selects(SQL::Query.new)

      query.from(esc_i @table_name)

      if params[:conditions][:closest] && params[:conditions][:closest][:lon] && params[:conditions][:closest][:lat]
        query.order_by <<-END_CONDITION
          ST_Distance(
            ST_Transform(#{@table_info.geometry_column}, 4326), 
            ST_GeomFromText('POINT(#{ Float(params[:conditions][:closest][:lon]) } #{ Float(params[:conditions][:closest][:lat]) })', 4326)
          )
        END_CONDITION
      end

      params[:conditions][:is].each do |field, value|
        query.where "#{ esc_i field } = #{ i_or_quoted_s_for(value, field) }"
      end

      params[:conditions][:in].each do |field, values|
        query.where "#{ esc_i field } IN (#{ values.map { |v| i_or_quoted_s_for(v, field) }.join(", ") })"
      end

      params[:conditions][:contains].each do |field, value|
        query.where "#{ esc_i field }::varchar ILIKE '%#{ esc_s value.gsub(/(?=[%_])/, "\\") }%'"
        query.order_by "position(upper('#{ esc_s value }') in upper(#{ esc_i field }::varchar))"
        query.order_by "#{ esc_i field }::varchar"
      end

      params[:conditions][:matches].each do |field, value|
        query.where <<-END_CONDITION
          #{ esc_i field } @@
          CASE
            WHEN char_length(plainto_tsquery('#{ esc_s value }')::varchar) > 0
            THEN to_tsquery(plainto_tsquery('#{ esc_s value }')::varchar || ':*')
            ELSE plainto_tsquery('#{ esc_s value }')
          END
        END_CONDITION
      end

      query.limit params[:conditions][:limit]
      
      Outcome.good(data: as_feature_collection(@connection.exec(query.to_sql).to_a))
    end

    private

    def esc_i identifier
      @connection.escape_identifier(identifier)
    end

    def esc_s string
      @connection.escape_string(string)
    end

    def i_or_quoted_s_for value, field
      @table_info.integer_col?(field) ? Integer(value).to_s : "'#{ esc_s value }'"
    end

    def with_normal_and_geo_selects(query)
      query.select(@table_info.normal_columns)
      query.select("ST_AsGeoJSON(ST_Transform(#{@table_info.geometry_column}, 4326), 15, 2) AS geometry_geojson") if @table_info.geometry_column
      query
    end

    def as_feature(result)
      {
        "type" => "Feature",
        "properties" => result.select { |k,v| k != :geometry_geojson }
      }.merge(
        begin
          if result[:geometry_geojson].to_s.empty?
            {}
          else
            { "geometry" => JSON.parse(result[:geometry_geojson]) }
          end
        end
      )
    end

    def as_feature_collection(results)
      {
        "type" => "FeatureCollection",
        "features" => results.map { |result| as_feature(result) }
      }
    end

  end
end

