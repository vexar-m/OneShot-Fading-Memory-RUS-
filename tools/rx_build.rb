require_relative 'stubs'
require 'fileutils'
en_dir, out_dir, dictfile = ARGV

by_file = Hash.new { |h, k| h[k] = {} }
raw = File.read(dictfile, encoding: 'UTF-8').sub(/\A\xEF\xBB\xBF/, '')
raw.each_line do |ln|
  ln = ln.chomp
  next if ln.empty? || ln.start_with?('#')
  p, en, ru = ln.split("\t", 3)
  next unless ru
  
  base = case p
         when /\A(Map\d+|Map-\d+|Items|Weapons|Armors|Skills|States|Actors|Classes|Enemies|System|CommonEvents|MapInfos|Animations|Tilesets|Troops)/
           $1
         when /\A([^.@]+)\.\d+@/
           $1
         when /\A([^.@]+)@/
           $1
         else
           p.split('@', 2)[0]
         end
  by_file[base][p] = unesc(ru)
end

by_file.each do |base, map|
  src = File.join(en_dir, "#{base}.rxdata")
  unless File.exist?(src)
    warn "SKIP no pristine: #{base}"
    next
  end
  obj = rx_load(src)
  applied = {}
  w = nil
  w = lambda do |o, p|
    case o
    when Array
      o.each_with_index do |x, i|
        np = "#{p}.#{i}"
        if map.key?(np) && o[i].is_a?(String)
          o[i] = map[np]
          applied[np] = true
        else
          w.call(x, np)
        end
      end
    when Hash
      o.each do |k, v|
        np = "#{p}[#{k}]"
        if map.key?(np) && o[k].is_a?(String)
          o[k] = map[np]
          applied[np] = true
        else
          w.call(v, np)
        end
      end
    else
      o.instance_variables.each do |iv|
        np = "#{p}#{iv}"
        v = o.instance_variable_get(iv)
        if map.key?(np) && v.is_a?(String)
          o.instance_variable_set(iv, map[np])
          applied[np] = true
        else
          w.call(v, np)
        end
      end
    end
  end
  w.call(obj, base)
  warn "#{base}: applied=#{applied.size}"
  FileUtils.mkdir_p(out_dir)
  rx_save(File.join(out_dir, "#{base}.rxdata"), obj)
end
warn "BUILD DONE"