# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>
###########################################################################
#                        S t a r 
###########################################################################
class Star
  attr_accessor :x, :y, :type,:r
  
  def initialize(ls,type,animation)
    @animation = animation
    @index=ls.size
    @ls=ls
    @type=type
    @r=@type ? 10 : $RANGE_STAR_SIZE.rand() 
    @no_img= type ? 1 : (rand()>0.5 && @r>35) ? 0 : (rand(3)+2)
    @rot=rand(180)
    ok=(@type || rand()<0.4)
    p "nok" unless ok
    @show= ok  ? 1000 : 0
    @color = Gosu::Color.new(0xff000000 )
    @color.red =   type ? 255 : 200
    @color.green = type ? 0   : 200 
    @color.blue =  type ? 0   : 200
    @x = (SX/7..(SX-SX/7)).rand
    @y = (SY/7..(SY-SY/7)).rand
    #@x = (index % 10) * (SX/10)
    #@y = (index / 10) * (SY/10)
	end
  def index() @index end
  
  ########### Net

  def self.create(anim,no_img,r,rot)
	Star.new([],10,anim).reinit(no_img,r,rot)
  end
  def reinit(no_img,r,rot,colors) 
		@no_img,@r,@rot = no_img,r,rot
		@color.red,@color.green,@color.blue=*colors
		self 
  end  
  def serialize(i)  
	[i,[@no_img,@r,@rot,[@color.red,@color.green,@color.blue]],[@x,@y]] 
  end
  
  def update(x,y)  @x,@y=x,y end
  
  def get_pos()
	[@x.to_i,@y.to_i,@type,@index,@r,@no_img]
  end
  def set_pos(pos)
    @x,@y,@type,@index,@r,@no_img=*pos
  end
  ####### serveur side behavior
  def move(game,ls)
    ox,oy=@x,@y
	expand(game,ls)
	@x=ox if @x>(SX-40) || @x<40
	@y=oy if @y>(SY-40) || @y<40
	
  end
  def expand(game,ls) 
	 return unless game.pending?(40)
     motion(ls,self,-100.0,110) { |o| ! o.type} if type    # Star   <-> Planet
     motion(ls,self,-10.0,50)   { |o| o.type}             # *      <-> Star
     motion(ls,self,-10.0,500)  { |o| ! o.type } if !type # Planet <-> Planet
  end
  
  ####### draw client+server side
  def draw()
    @show+=0.8 if @show<1000
    return unless @show>10
    img = @animation[@no_img]
    fx=(@r/40.0)*(@show/1000.0)
    img.draw_rot(@x, @y, ZOrder::Stars, @rot, 0.5,0.5 ,fx,fx,@color)
  end
end

