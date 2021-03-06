require 'test_helper'
require 'simplesem'

class SimpleSemParserTest < Test::Unit::TestCase
  include ParserTestHelper
  
  def setup
    @parser = SimpleSem::SimpleSemParser.new
    @ssp = SimpleSem::Program.new
    @ssp.data[0] = [1]
  end

  def test_version_constant_is_set
    assert_not_nil SimpleSem::VERSION
  end
  
  def test_set_stmt_assign
    parse('set 1, D[0]').execute(@ssp)
    assert_equal [[1], [1]], @ssp.data
  end
  
  def test_set_stmt_write_string
    out = capture_stdout do
      parse('set write, "Hello World!"').execute(@ssp)
    end
    assert_equal "Hello World!\n", out.string
  end
  
  def test_set_stmt_write_expr
    out = capture_stdout do
      parse('set write, 2 > 1').execute(@ssp)
    end
    assert_equal "true\n", out.string
  end
  
  def test_set_stmt_read
    fake_in = StringIO.new("2\n3\n")
    $stdin = fake_in
    
    capture_stdout do     # capture_stdout because we do not want "input:"'s in the test output
      parse('set 1, read').execute(@ssp)
      parse('set 1, read').execute(@ssp)
    end
    assert_equal [2, 3], @ssp.data[1]
  end
  
  def test_jump_stmt
    parse('jump 5').execute(@ssp)
    assert_equal 5, @ssp.pc
  end
  
  def test_set_to_data_loc
    parse('set D[0], 2').execute(@ssp)
    assert_equal 2, @ssp.data[1].last
  end
  
  def test_complex_expr
    @ssp.data[1] = [2]
    parse('set 2, D[0]+D[1]*2').execute(@ssp)
    assert_equal 5, @ssp.data[2].last
  end
  
  def test_parenthesis
    @ssp.data[1] = [2]
    parse('set 2, (D[0]+D[1])*2').execute(@ssp)
    assert_equal 6, @ssp.data[2].last
  end
  
  def test_set_increment_instr
    parse('set 0, D[0]+1').execute(@ssp)
    assert_equal 2, @ssp.data[0].last
  end
  
  def test_nested_data_lookup
    @ssp.data[0] = [0]
    @ssp.data[1] = [1]
    parse('set 2, D[D[0]+1]').execute(@ssp)
    assert_equal 1, @ssp.data[2].last
  end
  
  def test_instruction_pointer
    # manually incrementing the program counter is required here
    @ssp.pc = 1
    parse('set 0, ip').execute(@ssp)
    assert_equal 1, @ssp.data[0].last  # checking that the parser was able to evaluate ip correctly
  end
  
  def test_jump_to_data_loc
    @ssp.data[0] = [2]
    parse('jump D[0]').execute(@ssp)
    assert_equal 2, @ssp.pc
  end
  
  def test_jumpt_stmt_true
    @ssp.data[0] = [1]
    parse('jumpt 5, D[0]=D[0]').execute(@ssp)
    assert_equal 5, @ssp.pc
  end
    
  def test_jumpt_stmt_false
    @ssp.data[0] = [1]
    parse('jumpt 5, D[0]=2').execute(@ssp)
    assert_equal 0, @ssp.pc   # pc should not have changed
  end
  
  def test_less_than_comparison
    # test a jumpt that returns false
    parse('jumpt 5, D[0] < 0').execute(@ssp)
    assert_not_equal 5, @ssp.pc    
    
    parse('jumpt 5, D[0] < 2').execute(@ssp)
    assert_equal 5, @ssp.pc
  end
  
  def test_greater_than_comparison
    parse('jumpt 5, D[0] > 0').execute(@ssp)
    assert_equal 5, @ssp.pc    
  end
  
  def test_greater_than_or_eql_comparison
    parse('jumpt 5, 1 >= D[0]').execute(@ssp)
    assert_equal 5, @ssp.pc    
  end
  
  def test_less_than_or_eql_comparison
    parse('jumpt 5, 0 <= D[0]').execute(@ssp)
    assert_equal 5, @ssp.pc    
  end
  
  def test_negative_number
    parse('set 0, -1').execute(@ssp)
    assert_equal -1, @ssp.data[0].last
  end
  
  def test_halt
    assert_raise SimpleSem::ProgramHalt do
      parse('halt').execute(@ssp)
    end
  end
end
