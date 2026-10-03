require 'zlib'
raw = File.binread(ARGV[0] || 'Data/Scripts.rxdata')
arr = Marshal.load(begin; Zlib::Inflate.inflate(raw); rescue StandardError; raw; end)
dec = lambda do |c|
  begin; Zlib::Inflate.inflate(c); rescue StandardError; c; end
end
name = ARGV[1]
if name
  e = arr.find { |x| x[1] == name }
  puts e ? dec.call(e[2]) : "NOT FOUND"
else
  arr.each { |id, n, c| puts "#{id}\t#{n}\t#{dec.call(c).length}" }
end