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
          d[unescape(en)] = unescape(ru) if ru && !ru.empty?
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
        code = cmd.instance_variable_get(:@code)
        params = cmd.instance_variable_get(:@parameters)
        next unless params.is_a?(Array)
        case code
        when 101, 102, 105, 106, 401
          cmd.instance_variable_set(:@parameters, rep(params))
        when 355, 655
          s = params[0]
          params[0] = dict[s] if s.is_a?(String) && dict.key?(s)
        end
      end
    end
    data.instance_variable_set(:@zrt, true)
  end
  def self.install
    return if @installed
    return unless Object.const_defined?(:Game_CommonEvent)
    Game_CommonEvent.class_eval do
      alias_method(:_zrt_init, :initialize)
      def initialize(*a)
        ZRuntime.patch_ce($data_common_events)
        _zrt_init(*a)
      end
    end
    @installed = true
  end
end
class RubyVM::InstructionSequence
  class << self
    alias_method :_zrt_lib, :load_from_binary
    def load_from_binary(b)
      is = _zrt_lib(b)
      is.eval
      ZRuntime.install
      RubyVM::InstructionSequence.compile("")
    end
  end
end