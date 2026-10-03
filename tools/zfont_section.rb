module ZFontHook
  GOOD = "Terminus (TTF)"
  BAD = /Inconsolata|alarm clock|Cairo|DEADLYFONT/i
  def self.log(s)
    @f ||= File.open("z_font_log.txt", "ab")
    @f.puts(s)
    @f.flush
  rescue StandardError
    nil
  end
  def self.fix(v)
    names = v.is_a?(Array) ? v.map(&:to_s) : [v.to_s]
    return v unless names.any? { |s| s =~ BAD }
    log("REPLACE -> #{GOOD}")
    v.is_a?(Array) ? [GOOD] : GOOD
  end
  def self.guard(hook)
    d = (Thread.current[:zfh] ||= {})
    d[hook] = (d[hook] || 0) + 1
    if d[hook] > 8
      log("GUARD skip #{hook}")
      return false
    end
    true
  end
  def self.unguard(hook)
    d = (Thread.current[:zfh] ||= {})
    d[hook] -= 1
  end
end
class Font
  unless method_defined?(:__zi__)
    alias_method :__zi__, :initialize
    def initialize(*args)
      if ZFontHook.guard(:init)
        begin
          args[0] = ZFontHook.fix(args[0]) if args[0]
        ensure
          ZFontHook.unguard(:init)
        end
      end
      __zi__(*args)
    end
  end
  unless method_defined?(:__nm=)
    alias_method :__nm=, :name=
    def name=(v)
      if ZFontHook.guard(:name)
        begin
          v = ZFontHook.fix(v)
        ensure
          ZFontHook.unguard(:name)
        end
        self.__nm = v
      end
    end
  end
  class << self
    unless method_defined?(:__dn=)
      alias_method :__dn=, :default_name=
      def default_name=(v)
        if ZFontHook.guard(:dn)
          begin
            v = ZFontHook.fix(v)
          ensure
            ZFontHook.unguard(:dn)
          end
          self.__dn = v
        end
      end
    end
  end
end