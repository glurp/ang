# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
###########################################################################
#   multicast_test.rb : CLI tool for checking angm multicast communications
#--------------------------------------------------------------------------
# Usage
#      term1> ruby multi_cast_text.rb 
#      temr2> ruby multi_cast_text.rb 
#  otherhost> ruby multi_cast_text.rb
###########################################################################
require 'thread'
require 'timeout'
require_relative 'net.rb'


$id=((Time.now.to_f*1000).to_i)* 100 + rand(100)
Thread.abort_on_exception=true

STDOUT.sync=true
def log(*txt) puts "%-80s " % [txt.join(" ")] end


puts <<EEND
*****************************************************
             Multicast Test
			 
Checking Multicast group used by ANGM :
	MULTICAST_ADDR = #{MCast::MULTICAST_ADDR}
	PORT           = #{MCast::PORT}
	Interface      = #{MCast::BIND_ADDR}

If multicast do not work :
* check your route table, a entry should exist on 224.0.0.0
* check if virtual host are configured, 
* check multihoming (alias ip)
  if host ip showed in trace is not a ip binded in your physical
  interface, your multicast will work strangly...

My ID is #{$id}. this value is second parameter of 
each message sended/received (startup time in ms * 100 + random(100)
hoping ot will be unic on the network...

*****************************************************

EEND
sleep 4
class App
	def initialize
		NetClient.init(self)
		NetClient.set_trace(true)
		Thread.new { loop { NetClient.wait_and_invoke() } }
		Thread.new { 
			loop { 
				#NetClient.connect()
				log "\n\Sending echo..."
				NetClient.echo([$id,(Time.now.to_f*1000).to_i]) 
				sleep 4 
			} 
		}
		Thread.new { sleep 4 ; puts "\n\nEnd Traces\n\n"; NetClient.set_trace(false) }
	end
	def method_missing(name,*args)
		if name==:recho
			id_sender,id_demander,time=*args
			log("Echo timing for #{id_sender} : #{(Time.now.to_f*1000).to_i - time} ms") if id_demander==$id
		else
			log(("%15s : %s" % ["<#{name}>",args.inspect])[0..100]) if name!=:move && name!=:update_payers
		end
	end
end

app=App.new
sleep


