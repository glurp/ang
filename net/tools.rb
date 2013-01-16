# Creative Commons BY-SA :  Regis d'Aubarede <regis.aubarede@gmail.com>

module ZOrder
  Background, Stars, Player, UI = [0,1,2,3]
end
class Numeric
	def minmax(min,max=nil)
	  (max=min;min=-min) if !max
	  return self if self>=min && self<=max
	  return(min) if self<min
	  return(max)
	end
end
class Range ; def rand() self.begin+Kernel.rand((self.end-self.begin).abs) end ; end

# pseudo newton
def newton_xy1(p1,p2,a,b)
 k1=1.0/40
 k2=1.0/40000
 dx,dy=[a.x-b.x,a.y-b.y]
 d=Math::sqrt(dx ** 2 + dy ** 2)
 f1=(k1*p1*p2/(d*d+100)).minmax(100)
 f2=(k2*p1*p2/(d)).minmax(100)
 f=0.8*[f1,f2].max
 #p [f,f1,f2]
 teta=Math.atan2(dy,dx)   
 r=[-f*Math.cos(teta),-f*Math.sin(teta)]
 r
end

# newton, with  'amrtissement'
def newton_xy(p1,p2,a,b,k=1.0/300,dmin=10,dmax=10000)
 dx,dy=[a.x-b.x,a.y-b.y]
 d=dmin+Math::sqrt(dx ** 2 + dy ** 2)
 return [0,0] if d>dmax
 #f=(k*p1*p2/(d*d)).minmax(100) : k/d**2 not good for gameplay
 f=(k*p1*p2/(d*d-dmin*dmin)).minmax(10)
 teta=Math.atan2(dy,dx)   
 [-f*Math.cos(teta),-f*Math.sin(teta)]
end

# apply gravity between obj and a list l of planet
# k=coef gr&avity, >0 attraction, <0 repulsion
# dmaw : distance max, no attaction if distance>dmax
def motion(l,obj,k,dmax) 
 dx,dy=0,0
 l.each do |o| 
	next if o==obj
	next if block_given?  && ! yield(o)
	dx1,dy1= newton_xy(obj.r,o.r,obj,o,k,0,dmax)
	dx+=dx1
	dy+=dy1
  end
  obj.x+=dx
  obj.y+=dy
  return Math.sqrt(dx*dx+dy*dy)
end

