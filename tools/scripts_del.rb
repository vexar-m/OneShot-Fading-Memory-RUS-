require 'zlib'
name = ARGV[0]
raw = File.binread('Data/Scripts.rxdata')
arr = Marshal.load(begin; Zlib::Inflate.inflate(raw); rescue StandardError; raw; end)
n0 = arr.size
arr.reject! { |e| e[1] == name }
dump = Marshal.dump(arr)
File.binwrite('Data/Scripts.rxdata', dump)
File.binwrite('Data/xScripts.rxdata', dump) if File.exist?('Data/xScripts.rxdata')
warn "removed #{name} (#{n0} -> #{arr.size})"