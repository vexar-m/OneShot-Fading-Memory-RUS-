require_relative 'stubs'
src = ARGV[0] or raise "usage: ce_extract.rb <CommonEvents.rxdata>"
data = rx_load(src)
dict = Hash.new(0)
add = lambda do |s|
  next unless s.is_a?(String) && !s.empty? && s.valid_encoding?
  next if s =~ /\A[\x00-\x08\x0B\x0C\x0E-\x1F]/
  dict[s] += 1
end
scan = lambda do |o|
  case o
  when String then add.call(o)
  when Array  then o.each { |x| scan.call(x) }
  when Hash   then o.each_value { |x| scan.call(x) }
  end
end
data.each do |ce|
  list = ce.instance_variable_get(:@list)
  next unless list.is_a?(Array)
  list.each do |cmd|
    params = cmd.instance_variable_get(:@parameters)
    scan.call(params) if params.is_a?(Array)
  end
end
File.open('ce_src.tsv', 'w', encoding: 'UTF-8') do |f|
  f.puts("# unique=#{dict.size}")
  dict.each { |s, c| f.puts("#{c}\t#{esc(s)}\t") }
end
warn "ce_src.tsv: #{dict.size}"