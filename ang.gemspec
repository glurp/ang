# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name     = "ang"
  s.version  = File.read("VERSION").strip
  s.date     = Time.now.to_s.split(/\s+/)[0]
  s.email    = "regis.aubarede@gmail.com"
  s.homepage = "http://github.com/raubarede/ang"
  s.authors  = ["Regis d'Aubarede"]
  s.summary  = "A 2D planetoid navigation game"
  s.description = <<EEND
Intersideral navigation
EEND
  
  dependencies = [
    [:runtime,     "gosu"],
	]
  
  s.files         = Dir['**/*']
  s.executables   = ["ang","angm"]
  s.bindir		  = "bin"
  
  
  ## Make sure you can build the gem on older versions of RubyGems too:
  s.rubygems_version = "1.8.15"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.specification_version = 3 if s.respond_to? :specification_version
  
  dependencies.each do |type, name, version|
    if s.respond_to?("add_#{type}_dependency")
      s.send("add_#{type}_dependency", name, version)
    else
      s.add_dependency(name, version)
    end
  end
 s.post_install_message = <<TTEXT

      -------------------------------------------------------------------------------

      Hello, welcome to ang game....

        $ ang    # simple easy training
        $ angm   # multi gamer, harder

      -------------------------------------------------------------------------------
TTEXT
end

