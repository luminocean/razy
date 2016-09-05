require 'minitest/spec'
require 'minitest/autorun'
require_relative '../razy'

class TestFileIO < Minitest::Test
  def setup
    @razy = Razy.new
    @test_file_path = File.join(File.dirname(__FILE__), 'test.txt')
  end

  def before
    File.open(@test_file_path, 'w') do |file|
      file.write('') # empty test file
    end
  end

  def teardown
    File.unlink(@test_file_path)
  end

  def test_async_file_io
    pass = false

    main = lambda do
      test_text = 'HELLO WORLD!'

      @razy.write_file(@test_file_path, test_text) do |err|
        @razy.read_file(@test_file_path) do |err, file|
          if test_text == file
            pass = true
          end
        end
      end
    end

    @razy.start(main)

    # Razy loop done, now check whether the test case passes
    assert(pass)
  end
end