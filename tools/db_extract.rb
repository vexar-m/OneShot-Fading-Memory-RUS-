require_relative 'stubs'
dir = ARGV[0]
DB = {
  "Items" => [:description], "Weapons" => [:description],
  "Armors" => [:description], "Skills" => [:description],
}
out = File.open('db_src.tsv', 'w', encoding: 'UTF-8')
total = 0
DB.each do |base, fields|
  f = File.join(dir, base + '.rxdata')
  next unless File.exist?(f)
  rx_load(f).each_with_index do |el, i|
    fields.each do |fd|
      v = el.instance_variable_get("@#{fd}")
      next unless v.is_a?(String) && !v.empty? && v.valid_encoding?
      out.puts("#{base}.#{i}@#{fd}\t#{esc(v)}\t")
      total += 1
    end
  end
end
sys = rx_load(File.join(dir, 'System.rxdata'))
terms = sys.instance_variable_get(:@terms)
if terms
  w = nil
  w = lambda do |o, p|
    case o
    when String
      if !o.empty? && o.valid_encoding? then out.puts("#{p}\t#{esc(o)}\t"); total += 1 end
    when Array then o.each_with_index { |x, i| w.call(x, "#{p}.#{i}") }
    when Hash then o.each { |k, v| w.call(v, "#{p}[#{k}]") }
    else o.instance_variables.each { |iv| w.call(o.instance_variable_get(iv), "#{p}#{iv}") }
    end
  end
  w.call(terms, "System@terms")
end
out.close
warn "db_src.tsv: #{total}"