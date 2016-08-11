require_relative 'razy'

main = proc do
  # asynchronized read
  Razy.read('./text') do |err, file1|
    Razy.read('./text') do |err, file2|
      puts file1+'*'+file2
    end
    puts 'Hold on...'
  end

  puts 'go go go!'
end

# launch main loop
Razy.start(main)
