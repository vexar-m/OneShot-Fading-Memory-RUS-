require_relative 'stubs'
obj = rx_load(ARGV[0])
walk = nil
walk = lambda do |o, p|
  case o
  when String then puts "#{p}\t#{esc(o)}"
  when Array  then o.each_with_index { |x, i| walk.call(x, "#{p}.#{i}") }
  when Hash   then o.each { |k, v| walk.call(v, "#{p}[#{k}]") }
  else o.instance_variables.each { |iv| walk.call(o.instance_variable_get(iv), "#{p}#{iv}") }
  end
end
walk.call(obj, File.basename(ARGV[0], '.rxdata'))