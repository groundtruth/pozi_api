require "pg"
require "pg_typecast"

class PGresult
  alias_method :typecast_each, :each

  def each &given_block
    row = 0
    typecast_each do |typecast_row|

      fixed_row = {}
      typecast_row.each do |k,v|
        if v.kind_of?(String)
          fixed_row[k] = self[row][k.to_s]
        else
          fixed_row[k] = v
        end
      end

      given_block.call(fixed_row)
      row += 1
    end
  end

end

