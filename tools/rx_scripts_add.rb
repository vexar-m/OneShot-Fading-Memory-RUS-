require 'zlib'
name, codefile = ARGV
load_s = lambda do |f|
  raw = File.binread(f)
  Marshal.load(begin; Zlib::Inflate.inflate(raw); rescue StandardError; raw; end)
end
arr = load_s.call('Data/Scripts.rxdata')
code = Zlib::Deflate.deflate(File.read(codefile, encoding: 'UTF-8'))
arr.reject! { |e| e[1] == name }
idx = arr.index { |e| e[1] == 'Main' } or raise "Main not found"
id = arr.map { |e| e[0] }.max + 1
arr.insert(idx, [id, name, code])
dump = Marshal.dump(arr)
File.binwrite('Data/Scripts.rxdata', dump)
File.binwrite('Data/xScripts.rxdata', dump) if File.exist?('Data/xScripts.rxdata')
warn "added #{name}"