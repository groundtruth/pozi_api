require "pg"
require "pg_typecast"

# This patch is a workaround for the issue:
#   "Strings loose original encoding and are presented as ASCII-8BIT"
#   https://github.com/deepfryed/pg_typecast/issues/2

class PGresult
  alias_method :typecast_each, :each

  def each &given_block
    row = 0
    typecast_each do |typecast_row|

      fixed_row = Hash[typecast_row.map do |k,v|
        fixed_v = v.kind_of?(String) ? self[row][k.to_s] : v
        [k, fixed_v]
      end]
      given_block.call fixed_row

      row += 1
    end
  end

end

