require_relative 'stubs'
require 'fileutils'
en_dir, out_dir, dictfile = ARGV
by_file = Hash.new { |h, k| h[k] = {} }
File.foreach(dictfile, encoding: 'UTF-8') do |ln|
  ln = ln.chomp
  next if ln.empty? || ln.start_with?('#')
  p, en, ru = ln.split("\t", 3)
  next unless ru
  by_file[p.split('@', 2)[0]][p] = unesc(ru)
end
by_file.each do |base, map|
  src = File.join(en_dir, base + '.rxdata')
  unless File.exist?(src)
    warn "SKIP no pristine: #{base}"; next
  end
  obj = rx_load(src)
  applied = {}
  w = nil
  w = lambda do |o, p|
    case o
    when Array
      o.each_with_index do |x, i|
        np = "#{p}.#{i}"
        if map.key?(np) && o[i].is_a?(String) then o[i] = map[np]; applied[np] = true else w.call(x, np) end
      end
    when Hash
      o.each do |k, v|
        np = "#{p}[#{k}]"
        if map.key?(np) && o[k].is_a?(String) then o[k] = map[np]; applied[np] = true else w.call(v, np) end
      end
    else
      o.instance_variables.each do |iv|
        np = "#{p}#{iv}"; v = o.instance_variable_get(iv)
        if map.key?(np) && v.is_a?(String) then o.instance_variable_set(iv, map[np]); applied[np] = true else w.call(v, np) end
      end
    end
  end
  w.call(obj, base)
  missed = map.keys.reject { |k| applied[k] }
  warn "#{base}: applied=#{applied.size} missed=#{missed.size}"
  missed.first(5).each { |k| warn "   MISS #{k}" }
  FileUtils.mkdir_p(out_dir)
  rx_save(File.join(out_dir, base + '.rxdata'), obj)
end
warn "BUILD DONE"