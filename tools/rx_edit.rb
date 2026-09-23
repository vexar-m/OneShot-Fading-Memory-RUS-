require_relative 'stubs'
obj = rx_load(ARGV[0])
edits = {}
raw = File.read(ARGV[1], encoding: 'UTF-8').sub(/\A\xEF\xBB\xBF/, '')
raw.each_line do |ln|
  ln = ln.chomp
  next if ln.empty? || ln.start_with?('#')
  pth, val = ln.split("\t", 2)
  edits[pth] = unesc(val) if val
end
count = 0
set = nil
set = lambda do |o, p|
  case o
  when Array
    o.each_with_index do |x, i|
      np = "#{p}.#{i}"
      if edits.key?(np) && o[i].is_a?(String) then o[i] = edits[np]; count += 1 else set.call(x, np) end
    end
  when Hash
    o.each do |k, v|
      np = "#{p}[#{k}]"
      if edits.key?(np) && o[k].is_a?(String) then o[k] = edits[np]; count += 1 else set.call(v, np) end
    end
  else
    o.instance_variables.each do |iv|
      np = "#{p}#{iv}"; v = o.instance_variable_get(iv)
      if edits.key?(np) && v.is_a?(String) then o.instance_variable_set(iv, edits[np]); count += 1 else set.call(v, np) end
    end
  end
end
set.call(obj, File.basename(ARGV[0], '.rxdata'))
rx_save(ARGV[0], obj)
warn "applied #{count}/#{edits.size}"