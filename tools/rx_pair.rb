require_relative 'stubs'
en_dir, ru_dir, out = ARGV
total = 0
File.open(out, 'w', encoding: 'UTF-8') do |f|
  f.puts "# path\tEN\tRU"
  files = Dir.glob(File.join(en_dir.tr('\\', '/'), '*.rxdata')).sort
  warn "pristine files found: #{files.length}"
  files.each do |ef|
    base = File.basename(ef)
    next if base =~ /\A(Scripts|xScripts|xIseq)\.rxdata\z/
    rf = File.join(ru_dir, base)
    next unless File.exist?(rf)
    a = rx_load(ef); b = rx_load(rf)
    pa = {}; pb = {}
    walk = nil
    walk = lambda do |o, p, h|
      case o
      when String then h[p] = o
      when Array  then o.each_with_index { |x, i| walk.call(x, "#{p}.#{i}", h) }
      when Hash   then o.each { |k, v| walk.call(v, "#{p}[#{k}]", h) }
      else o.instance_variables.each { |iv| walk.call(o.instance_variable_get(iv), "#{p}#{iv}", h) }
      end
    end
    root = base.sub(/\.rxdata\z/, '')
    walk.call(a, root, pa)
    walk.call(b, root, pb)
    cnt = 0
    pa.each do |p, en|
      ru = pb[p]
      next if ru.nil? || ru == en
      next unless en.valid_encoding? && ru.valid_encoding?
      f.puts "#{p}\t#{esc(en)}\t#{esc(ru)}"
      cnt += 1
    end
    warn "#{base}: #{cnt}" if cnt > 0
    total += cnt
  end
end
warn "dict written, total diffs: #{total}"