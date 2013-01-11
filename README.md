ANG : spacial navigation micro-game
==================================

Navigate in space, pursuite some star and use planet gravity to
navigate.

In developpement,
Working, but missing menu, setup, level choice ....


Free to use, modify and distribute.

News : in net diretory, begining ang on multi-player

* multicast between all member on LAN
* not ready ! fro naow, only play all ship on all game instance

Inspiration
===========

Demo of gosu
Raster file come directly from these.
Code is remasterised a lot

http://regisaubarede.posterous.com/tag/game

Physics
=======
Newton law ( K.M.m/Dist**2 ) give a gameplay too reactive, so I use my own gravity version :)

Requirement
===========

Git,Ruby, gosu

```
 install ruby 1.9.X
 > gem install gosu
 > gem install ang
 > ang

 or
 > git clone http://github.com/raubarede/ang.git
 > cd ang
 > ruby main.rb
```