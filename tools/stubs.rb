require 'zlib'
module RPG
  class AudioFile; end
  class MoveRoute; end
  class MoveCommand; end
  class EventCommand; end
  class MapInfo; end
  class Tileset; end
  class Actor; end
  class Class; end
  class Class; end
  class Learning; end
  class Skill; end
  class Item; end
  class Weapon; end
  class Armor; end
  class Enemy
    class Action; end
  end
  class Troop
    class Member; end
    class Page
      class Condition; end
    end
  end
  class State; end
  class Animation
    class Frame; end
    class Timing; end
  end
  class CommonEvent; end
  class System
    class Terms; end
    class Words; end
    class TestBattler; end
  end
  class Map; end
  class Event
    class Page
      class Condition; end
      class Graphic; end
    end
  end
end
class Table
  def self._load(d); t = allocate; t.instance_variable_set(:@raw, d); t; end
  def _dump(_l); @raw; end
end
class Color
  def self._load(d); t = allocate; t.instance_variable_set(:@raw, d); t; end
  def _dump(_l); @raw; end
end
class Tone
  def self._load(d); t = allocate; t.instance_variable_set(:@raw, d); t; end
  def _dump(_l); @raw; end
end
def force_utf8(o)
  case o
  when String then o.force_encoding(Encoding::UTF_8)
  when Array  then o.each { |x| force_utf8(x) }
  when Hash   then o.each_value { |x| force_utf8(x) }
  else o.instance_variables.each { |iv| force_utf8(o.instance_variable_get(iv)) }
  end
  o
end
def rx_load(path)
  raw = File.binread(path)
  data = begin; Zlib::Inflate.inflate(raw); rescue StandardError; raw; end
  force_utf8(Marshal.load(data))
end
def rx_save(path, obj)
  File.binwrite(path, Zlib::Deflate.deflate(Marshal.dump(obj)))
end
def esc(s)
  s = s.scrub unless s.valid_encoding?
  s.gsub("\\") { "\\\\" }.gsub("\t") { "\\t" }.gsub("\n") { "\\n" }.gsub("\r") { "\\r" }
end
def unesc(s)
  s.gsub(/\\(\\|n|t|r)/) { { "\\" => "\\", "n" => "\n", "t" => "\t", "r" => "\r" }[$1] }
end