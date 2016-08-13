#! /usr/bin/env ruby

require_relative 'razy'

main = proc do
  Razy.read('./text') do |err, file|
    Razy.write('./text', "#{file}*") do |err|
      puts 'done!'
    end
    puts 'Hold on...'
  end
  puts 'go go go!'
end

# launch main loop
Razy.start(main)