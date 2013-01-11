###########################################################################
#   ANG.RB : planetoide game
#--------------------------------------------------------------------------
# install ruby
# install Gosu	> gem install gosu
# download this > git http://github.com/rdaubarede/ang.git
# run			> ruby main.rb
# do your own version :
#      > loop { edit/main.rb ; ruby main.rb }
# make your disribution :
#      > ocra main.rb
#
###########################################################################
require 'thread'
require 'timeout'
require 'gosu'
require 'zmq'



##################### Tuning ##########################

KK= 0.5 
KKI= KK / 2
SX=1280 / KK # window size width
SY=900 / KK  #             height

$INITIALE_SCORE=2000
$NB_STAR=55
$RANGE_STAR_SIZE=(20..40) # more planet / bigger planets ==>> harder game!
$NB_PLANET=3

#######################################################
 


$id=((Time.now.to_f*1000).to_i)* 100 + rand(100)
Thread.abort_on_exception=true

STDOUT.sync=true
def log(*txt) puts "%-80s | %s" % [txt.join(" "),caller[0].to_s.split(':in',2)[0]] end


require_relative 'tools.rb'
require_relative 'net.rb'
require_relative 'star.rb'
require_relative 'player.rb'


###########################################################################
#                        W i n d o w
###########################################################################

class GameWindow < Gosu::Window
  attr_reader :star,:ping
  def init_player(id)
    player = Player.new(self,@player_anim,false)    
    player.warp(320, 240)
    @players[id]=player
  end
  def del_player(id) @players.delete(id) end
  def initialize
    super((SX*KKI).to_i, (SY*KKI).to_i, false)
    self.caption = "Gosu Tutorial Game"
	@player_anim=  Gosu::Image::load_tiles(self, "Starfighter.bmp", 50,50, false)
    
	@lp=[]; 100.times { x=rand(SX) ; y=rand(SY); @lp<<x;@lp<<y }
    @players={}
	
	@player = Player.new(self,@player_anim,true)    
	@player.warp(SX*KKI/2,SY*KKI/2)
	
    @font = Gosu::Font.new(self, Gosu::default_font_name, (20/KK).round)
    @font2 = Gosu::Font.new(self, Gosu::default_font_name, (40/KK).round)

    @star_anim = Gosu::Image::load_tiles(self, "Star.bmp", 100,100, false)
	@ping=0
	@start=0
	@mouse=nil
    self.go("Start")
  end

	######################## Game global state 
	
	def looser() ego("Lose") end
	def winner(n) ego("Winner #{n}") end
	def ego(text)
		return if @ping < @start
	    puts "ego #{text}"
		@text=text
		@start=@ping+200
		Thread.new { sleep 2 ; self.go("Start") }
	end
	def go(text)
		@start=@ping+200
		@text=text
		@stars = Array.new
		@player.restart
		$NB_PLANET.times { @stars.push( Star.new(@stars,false,@star_anim) ) }
		$NB_STAR.times { @stars.push( Star.new(@stars,true,@star_anim) ) }
	end
	def pending?(d=0) (@start+d > @ping) end

	def send_positions(id)
		puts "send stars to #{id}"
		stars=@stars.map { |s| s.get_pos() }
		p [id,stars]
		NetClient.send_position([id,stars])
	end
	def	get_positions(id,data)
	    id_dest,stars=data
		puts "get pos for #{id} / #{$id}"
		if id_dest==$id
			stars.zip(@stars) { |pos,star| star.set_pos(pos) }
		end
	end
	
	######################## Global interactions  : mouse/keyboard
	
	########### Server+client
	
	def interactions_net()
		@players.each { |id,p| p.move(@stars) }
	end
	def update_payers(id,data) 
		if @players[id]
			@players[id].update_by_net(data) 
		end
	end

	########### client
	
	def update_star(id,type,pos) 
		i=id.to_i
		if @stars.size<=i
			while @stars.size<=i
				@stars<< Star.new([],type,@star_anim)
			end
			@stars[i].reinit(*type)
		end
		@stars[i].update(*pos)
	end
	
	def button_down(id)
		if id == Gosu::KbEscape
			NetClient.is_stoping()  
		end
	end
	
	def interactions_client()
		k=nil
		(@player.turn_left;k=Gosu::KbLeft)        if button_down? Gosu::KbLeft       or button_down? Gosu::GpLeft 
		(@player.turn_right;k=Gosu::KbRight)      if button_down? Gosu::KbRight      or button_down? Gosu::GpRight
		(@player.accelerate(true);k=Gosu::KbUp)   if button_down? Gosu::KbUp   or button_down? Gosu::GpButton0
		(@player.accelerate(false);k=Gosu::KbDown)if button_down? Gosu::KbDown or button_down? Gosu::GpButton1
	end
	
	######################## Global draw : update()/draw() are invoked continuously by Gosu engine
	
	def update()
		@ping+=1
		@player.clear() 
		
		@stars.each { |star| star.move(self,@stars) }
		return if @ping<@start
		
		interactions_net()
		interactions_client() 
		@players.each { |id,p| 
			p.move(@stars) ; p.collect_stars(@stars) 
		} 
		@player.move(@stars) 
	end
	
	def draw
		scale(KKI,KKI) {
			#draw_background
			@players.each {|id,p| p.draw(self,@stars) }
			@player.draw(self,@stars) 
			@stars.each { |star| star.draw() }
			draw_variable_background()
		}
	end
	def draw_background
		@lp.each_slice(2) do |x,y| 
			draw_triangle(
				x, y, 0xAAFFFFFF, 
				x+(4..8).rand, y+(4..8).rand,  0xAAFFFFFF, 
				x+(4..8).rand, y,  0xAAFFFFFF)
		end
	end		
	def draw_variable_background()
		if @ping<@start
			@font2.draw(@text+ "  ! !", SX/2, SY/2, ZOrder::UI, 1.0, 1.0, 0xf0f0f000)
			@font.draw("", 10, 10, ZOrder::UI, 1.0, 1.0, 0xffffff00)
		else		
			#----------- barr graph energies reserve level
			h=5+(@player.score/2000.0)*(SY-10)
			draw_quad(5, 5, 0xBB55FF55, 20/KK, 5,  0xBB55FF55, 20/KK, h,  0xBBFFFF55, 5 , h , 0xBBFFFF55)
			
			#------------ textual energie reserve level
			@font.draw("Score: #{@player.score}", 25/KK, 10/KK, ZOrder::UI, 1.0, 1.0, 0xffffff00)
		end
	end
end

$game=GameWindow.new
NetClient.init($game) 
$game.show
