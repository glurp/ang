comments=ARGV.join(" ")
exit! if comments.size==0

version=File.read("VERSION").strip.to_f
version= ((version*100)+1).round*0.01
open("VERSION","w") { |f| f.print(version.to_s) }
puts "New Version=#{version}"

system("git","commit","-a","-m","#{comments}")
system("git push") # put your password in .git/config : http://name:passwd@github...
puts "\n\nDone"
