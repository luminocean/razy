require_relative 'razy'

main = proc do
  # asynchronized read
  Razy.read('./text') do |err, file|
    puts file
  end

  puts 'go go go!'
end

# launch main loop
Razy.start(main)
