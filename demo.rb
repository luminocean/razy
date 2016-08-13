#! /usr/bin/env ruby

require_relative 'razy'

main = proc do
  Razy.read_file('./text') do |err, file|
    Razy.write_file('./text', "#{file}*") do |err|
      puts 'done!'
    end
    puts 'Hold on...'
  end
  puts 'go go go!'
end

# launch main loop
Razy.start(main)