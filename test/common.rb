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