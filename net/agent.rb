# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
###########################################################################
#   agent.rb : planetoide game multi player
#--------------------------------------------------------------------------
# install ruby
# install Gosu	> gem install gosu
# download this > gem install ang
# run			> angm
###########################################################################
require 'thread'
require 'timeout'
begin
	require 'gosu'
rescue Exception => e
	puts "Not completly installed !\nPlease do : \n> gem install gosu"
	sleep(3)
	exit(0)
end


##################### Tuning ##########################

KK= 0.5 
KKI= KK / 1
SX=1280 / KK # window size width
SY=900 / KK  #             height

$INITIALE_SCORE=20000
$NB_STAR=55
$RANGE_STAR_SIZE=(10..40) # more planet / bigger planets ==>> harder game!
$NET_TRANSMIT=80
$NB_PLANET=6
$NB_PL=$NB_STAR+$NB_PLANET
#######################################################
 


$id=((Time.now.to_f*1000).to_i)* 100 + rand(100)
sleep(0.01*($id%100))
Thread.abort_on_exception=true

STDOUT.sync=true
def log(*txt) puts "%-80s | %s" % [txt.join(" "),caller[0].to_s.split(':in',2)[0]] end


require_relative 'tools.rb'
require_relative 'net.rb'
require_relative 'star.rb'
require_relative 'player.rb'
require_relative 'missile.rb'


###########################################################################
#                        W i n d o w
###########################################################################

class GameWindow < Gosu::Window
  attr_reader :star,:ping
  def initialize
    super((SX*KKI).to_i, (SY*KKI).to_i, false)
	# "KbRangeBegin", "KbEscape", "KbF1",..., "KbF12", "Kb1", ... "Kb0", "KbA",... "KbZ", 
	# "KbTab", "KbReturn", "KbSpace", "KbLeftShift", "KbRightShift", "KbLeftControl", 
	# "KbRightControl", "KbLeftAlt", "KbRightAlt", "KbLeftMeta", "KbRightMeta", 
	# "KbBackspace", "KbLeft", "KbRight", "KbUp", "KbDown", "KbHome", "KbEnd", 
	# "KbInsert", "KbDelete", "KbPageUp", "KbPageDown", "KbEnter", "KbNumpad1", ... "KbNumpad0", 
	# "KbNumpadAdd", "KbNumpadSubtract", "KbNumpadMultiply", "KbNumpadDivide", 
	# "KbRangeEnd", "KbNum"]
	
	@text_field =  Gosu::TextInput.new()
	@text_field.text = "Input..."
	self.text_input=@text_field
	@comment=""
	
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
    self.go("Multiplayer version, in development ! Start")
	NetClient.init(self)
	Thread.new {
		sleep 3
		if @players.size>0
			master=@players.keys.sort.first
			NetClient.connect()  if master<$id
		end
	}
  end

	######################## Game global state 
	def egow(text)
		@text=text
		@start=@ping+800
		go1(text)
	end
	def ego(text)
		return if @ping < @start
		@text=text
		@start=@ping+200
		Thread.new { sleep 4 ; self.go("Start...") }
	end
	def go(text)
		display_comment "Avaler les points rouges, consommer le moins d'energie possible..."
		@start=@ping+200
		@text=text
		go1(text)
	end
	def go1(text)
		@stars = Array.new
		@missiles=[]
		@player.restart
		@global_score=0
		@touch={}
		$NB_PLANET.times { @stars.push( Star.new(@stars,false,@star_anim) ) }
		$NB_STAR.times { @stars.push( Star.new(@stars,true,@star_anim) ) }
		if @players.size>0
			NetClient.connect()  
		end
	end
	def pending?(d=0) (@start+d > @ping) end
	
	def finish()
		egow("Game Over...")
	end
	def looser() egow("Game Over") end
	def winner(n) 
		return unless NetClient.is_master 
		NetClient.send_success() 
		ego("Success, Very good")  
	end
	def receive_success(id)
		ego("Success, Very good")  
	end
	def receive_echec(id)
		ego("Game over...")  
	end
    def recho(*args) end

	def send_positions(id)
		stars=@stars.map { |s| s.get_pos() }
		NetClient.send_position([id,stars])
	end
	def	get_positions(id,data)
	    id_dest,stars=data
		if id_dest==$id
			stars.zip(@stars) { |pos,star| star.set_pos(pos) }
		end
	end
	
	def star_deleted(index)
		@stars.delete_if { |star| star.index() == index}
	end
	
	def init_player(id)
		player = Player.new(self,@player_anim,false)    
		player.warp(320, 240)
		@players[id]=player
	end
	def del_player(id) @players.delete(id) end
	######################## Global interactions  : mouse/keyboard
	
	########### Server+client
	
	def update_payers(id,data) 
		if @players[id]
			@touch.delete(id) if @touch[id]
			@players[id].update_by_net(data) 
		else
			init_player(id)
			@players[id].update_by_net(data) 
		end
	end

	########### client
	
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
		if @missiles.select {|m| m.local }.size<= 20
		 (@player.fire_missile();k=Gosu::KbNumpad0)  if button_down? Gosu::KbNumpad0 or button_down? Gosu::KbInsert
		end
		if k==nil
			@kbcars
		end
	end
	def watchdog()
		t=false
		@touch.keys.each  { |id| (t=true; @players.delete(id)) if @players[id] }
		NetClient.reinit_master(@players.keys) if t
		@players.keys.each { |id| @touch[id]=true }
	end
	def add_missile(m)
		@missiles << m
	end
	def new_missile(data)
		@missiles << Missile.new(self,@player_anim,false,*data)	
	end
	def end_missile(id)
		@missiles.reject! {|m| m.id==id}
	end
	######################## Global draw : update()/draw() are invoked continuously by Gosu engine
	
	def update()
		@ping+=1
		watchdog() if @ping%60==0
		@player.clear() 
		NetClient.event_invoke()		
		now=Time.now.to_f
		@players.each { |id,pl| pl.move(@stars,now) } if @player.score>0
		@stars.each { |star| star.move(self,@stars) }
		return if @ping<@start
		missiles_behavior(now)
		
		if @player.score>0
			interactions_client()
			@player.move(@stars,now)
			@player.collect_stars(@stars)
		end
		@global_score=@player.score+@players.values.inject(0) { |sum,pl| (sum+pl.score) }
		winner(@global_score) if 0 == (@stars.select { |s| s.type }.size )
	end
	def missiles_behavior(now)
		@missiles.reject! do |m|			
			next(true) if m.move(@stars,now)
			m.draw(self,@stars)
			next(false ) unless m.local 
			if m.collision_players(@player)
				NetClient.end_missile([m.id])
				@player.dead				
				true
			elsif idpl=@players.detect {|id,player| m.collision_players(player) }
				NetClient.end_missile([m.id])
				idpl[1].dead
				true
			end
		end
	end
	
	def draw
		scale(KKI,KKI) {
			#draw_background
			@players.each {|id,p| p.draw(self,@stars) }
			@player.draw(self,@stars) 
			@stars.each { |star| star.draw() }
			@missiles.each { |m| m.draw(self,@stars) }
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
	def draw_text(text,option)
		w=option[:font].text_width(@text, option[:scale])
		h=10*option[:scale];
		option[:font].draw(text,
			option[:x]<0 ? -option[:x] : (option[:x]-w/2),
			option[:y]<0 ? -option[:y] : (option[:y]-h/2),
			ZOrder::UI,
			option[:scale],option[:scale],option[:color])
	end
	def draw_variable_background()
		if @ping<@start
			draw_text(@text+ "  ! !",x: SX/2,y: SY/2,scale: 1,color: 0xf0f0f000,font: @font2)
			draw_text("",x: 10,y: 10,scale: 1,color: 0xffffff00,font: @font)
		else		
			#----------- barr graph energies reserve level
			h=5+(@player.score/2000.0)*(SY-10)
			draw_quad(5, 5, 0xBB55FF55, 20/KK, 5,  0xBB55FF55, 20/KK, h,  0xBBFFFF55, 5 , h , 0xBBFFFF55)
			i=2
			@players.each { |id,player| 
				h=5+(player.score/2000.0)*(SY-10)
				draw_quad(
						20/KK*i    , 5, 0xBB55FF55, 
						20/KK*(i+1), 5,  0xBB55FF55, 
						20/KK*(i+1), h,  0xBBFF9090+i*0x1010, 
						20/KK*i    , h , 0xBBFF9090+i*0x1010)
				i+=1
			}			
			
			#------------ textual energie reserve level
			draw_text("Global Score: #{@global_score}", x: -25/KK,y: 10/KK,scale: 1,color: 0xffffff00,font: @font)
			#------------ is Master
			if NetClient.is_master
				draw_text("Master", x: 25/KK,y: 20/KK,scale: 1,color: 0xffffff00,font: @font)
			end
			#----------------- Input
			if @comment.size>0
				draw_text(@comment, x: SX/2,y: SY-100,scale: 1,color: 0xffeeeeee,font: @font)
			end
			s=@text_field.text
			if s && s.size>0
				if s =~/\.$/
					@text_field.text=""
					NetClient.comment(s[0..-1])
				end
				draw_text("Input (end with '.') : "+ s,x: SX/4,y: SY-100,scale: 1,color: 0xffeeeeee,font: @font)
			end
		end
	end
	def display_comment(text)
		@comment=text
		Thread.new { sleep 10; @comment="" }
	end
end

$game=GameWindow.new 
$game.show
