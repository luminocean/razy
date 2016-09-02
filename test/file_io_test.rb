require 'minitest/spec'
require 'minitest/autorun'
require_relative '../razy'

def test_async(test_case)
  async_pass = false

  # start a new thread to test aio functionality
  thread = Thread.new do
    main = proc do
      done = proc do |pass|
        async_pass = pass
      end
      test_case.call(done)
    end
    Razy.start(main)
  end

  thread.join
  assert(async_pass)
end

test_file_path = File.join(File.dirname(__FILE__), 'test.txt')

describe 'Test File IO' do
  before do
    File.open(test_file_path, 'w') do |file|
      file.write('') # empty test file
    end
  end

  it 'test asynchronized file IO' do
    test_text = 'HELLO WORLD!'

    test_case = proc do |done|
      Razy.write_file(test_file_path, test_text) do |err|
        Razy.read_file(test_file_path) do |err, file|
          if test_text == file
            done.call(true)
          else
            done.call(false)
          end
        end
      end
    end

    test_async(test_case)
  end

  after do
    File.unlink(test_file_path)
  end
end