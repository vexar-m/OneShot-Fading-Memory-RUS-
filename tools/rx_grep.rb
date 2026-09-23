require_relative 'stubs'
pat = Regexp.new(ARGV[0], Regexp::IGNORECASE)
dir = ARGV[1] || 'Data'
Dir.glob(File.join(dir, '*.rxdata')).sort.each do |f|
  next if File.basename(f) =~ /\A(Scripts|xScripts|xIseq)\.rxdata\z/
  begin
    obj = rx_load(f)
  rescue StandardError => e
    warn "SKIP #{f}: #{e.class}: #{e.message[0, 80]}"
    next
  end
  base = File.basename(f, '.rxdata')
  walk = nil
  walk = lambda do |o, p|
    case o
    when String
      puts "#{p}\t#{o}" if o.valid_encoding? && o =~ pat
    when Array then o.each_with_index { |x, i| walk.call(x, "#{p}.#{i}") }
    when Hash  then o.each { |k, v| walk.call(v, "#{p}[#{k}]") }
    else o.instance_variables.each { |iv| walk.call(o.instance_variable_get(iv), "#{p}#{iv}") }
    end
  end
  walk.call(obj, base)
end