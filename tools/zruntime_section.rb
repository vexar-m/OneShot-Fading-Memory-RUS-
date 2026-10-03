module ZRuntime
  def self.unescape(s)
    s.gsub(/\\(\\|n|t|r)/) { { "\\" => "\\", "n" => "\n", "t" => "\t", "r" => "\r" }[$1] }
  end
  def self.dict
    @dict ||= begin
      d = {}
      if File.exist?("ce_dict.tsv")
        raw = File.read("ce_dict.tsv").dup.force_encoding("UTF-8").sub(/\A\xEF\xBB\xBF/, "")
        raw.each_line do |ln|
          ln = ln.chomp
          next if ln.empty? || ln.start_with?("#")
          en, ru = ln.split("\t", 2)
          next if en.nil? || en.empty? || ru.nil? || ru.strip.empty?
          d[unescape(en)] = unescape(ru)
        end
      end
      d
    end
  end
  def self.rep(o)
    case o
    when String then dict.key?(o) ? dict[o] : o
    when Array then o.map { |x| rep(x) }
    when Hash then o.map { |k, v| [k, rep(v)] }.to_h
    else o
    end
  end
  def self.patch_ce(data)
    return if data.nil? || data.instance_variable_get(:@zrt)
    data.each do |ce|
      list = ce.instance_variable_get(:@list)
      next unless list.is_a?(Array)
      list.each do |cmd|
        next unless cmd.respond_to?(:code) && cmd.respond_to?(:parameters)
        case cmd.code
        when 101, 102, 105, 106, 401
          cmd.parameters = rep(cmd.parameters)
        when 355, 655
          s = cmd.parameters[0]
          cmd.parameters[0] = dict[s] if s.is_a?(String) && dict.key?(s)
        end
      end
    end
    data.instance_variable_set(:@zrt, true)
  end
end
class Object
  alias_method :_zrt_load_data, :load_data
  def load_data(fn)
    o = _zrt_load_data(fn)
    ZRuntime.patch_ce(o) if fn.to_s =~ /CommonEvents/
    o
  end
end