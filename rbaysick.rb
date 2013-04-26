#!/usr/bin/env ruby

if caller.empty? && ARGV.length > 0
  $file = ARGV[0]
else
  $file = caller.last.split(':').first
end

require 'pp'

class String
  def %(other)
    self + other.to_s
  end
end

class RBaysick
  @@variables = {}
  @@code = []
  @@line = 0

  def initialize(contents)
    $DONT_RUN = true # To avoid endless loops.

    contents.gsub!(/( |\()'([^\W]+)/, '\1:\2 ')

    contents.gsub!(/(^| |\()(:[^\W]+)/, '\1GET(\2)')

    contents.gsub!(/ IF (.*) THEN (.*)/, ' IF { \1 }.THEN { GOTO \2 }')
    contents.gsub!(/LET *\(([^ ]+) *:= *(.*)\)/, 'LET(\1) { \2 }')
    contents.gsub!(/(LET|INPUT)(\(| )GET\(/, '\1\2(')
    contents.gsub!(/ \(/, '(')

    contents.gsub!(/^(\d+) (.*)$/, 'line(\1) { \2 }')

#    contents.gsub!(/(\)|\}|[A-Z]) ([A-Z]+)/, '\1.\2')

    contents.gsub!(/ END /, ' __END ')
    contents.gsub!(/^RUN/, '__RUN')

    puts contents if $DEBUG
    eval contents
  end

  def __RUN
    while @@line > -1
      puts "#{@@line}: #{@@code[@@line].inspect}" if $DEBUG
      unless @@code[@@line].nil?
        @@increment = true
        @@code[@@line].call
        next unless @@increment
      end
      @@line += 1
    end
  end

  class If < Struct.new(:value)
    def THEN
      yield if value
    end
  end

  def method_missing(name, *args)
    puts "Missing: #{name.to_s}(#{args.map(&:inspect).join(', ')})" if $DEBUG
  end

  def variables
    @@variables
  end

  def line(line, &block)
    @@code[line] = block
  end

  def add(line, cmd, *args)
    puts "DEBUG2: #{cmd.to_s}(#{args.map(&:inspect).join(', ')})" if $DEBUG
    @@code[line] = send(cmd, *args)
  end

  def IF
    ::RBaysick::If.new(yield)
  end

  def PRINT(str)
    puts "PRINT(#{str.inspect})" if $DEBUG
    puts str
    true
  end

  def LET(name, &block)
    puts "LET(#{name.inspect}, #{block.inspect})" if $DEBUG
    @@variables[name] = block.call
  end

  def GET(name)
    puts "GET(#{name.inspect}) #=> #{@@variables[name].inspect}" if $DEBUG
    @@variables[name]
  end

  def INPUT(name)
    puts "INPUT(#{name.inspect})" if $DEBUG
    LET(name) { $stdin.gets.chomp.to_i }
  end

  def ABS(val)
    puts "ABS(#{val.inspect}) #=> #{val.abs.inspect}" if $DEBUG
    val.abs
  end

  def GOTO(line)
    @@increment = false
    @@line = line
  end

  def __END
    exit
  end
end

RBaysick.new(open($file).read) unless $DONT_RUN || ($0 != __FILE__)

