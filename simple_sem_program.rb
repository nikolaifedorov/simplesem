require 'rubygems'
require 'treetop'
dir = File.dirname(__FILE__)
require File.expand_path("#{dir}/arithmetic_node_classes")
Treetop.load File.expand_path("#{dir}/arithmetic")
Treetop.load File.expand_path("#{dir}/simple_sem")

class SimpleSemProgram
  attr_reader :code
  attr_accessor :data, :pc
  
  def initialize filepath=nil
    @code = Array.new
    if filepath
      IO.foreach(filepath) do |line|
        @code << line.split("//", 2)[0].strip # seperate the comment from the code
      end
    end
    
    @data = Array.new
    @pc = 0
  end
  # alias :ip :pc
  
  def run
    @parser = SimpleSemParser.new
    
    @pc = 0
    loop do
      @pc += 1
      instruction = @code[@pc-1]
      # puts "'#{instruction}'"
      begin
        @parser.parse(instruction).execute(self)
      rescue
        puts "program halted"
        break
      end
    end
  end
  
  def inspect_data
    puts "DATA:"
    @data.each_with_index do |item, index|
      puts "#{index}: #{item}"
    end
  end
end