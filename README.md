ANG : spacial navigation micro-game
==================================

Navigate in space, pursuite some star and use planet gravity to
navigate.

In developpement,
Working, but missing menu, setup, level choice ....


Free to use, modify and distribute.


Multigamer
=========


In net directory, a ang game, version  multi-player on local network,
use Multicast (so work only on LAN).

The game : same as ang, but all players must collaborate for destroy a 
maximum of stars.

Usage:
  > angm

For checking multicast working, and timings on your host/network :
  > angm_net_test  # can be run multiple in same host and/or on distinct host

On my host, I get
* 23 ms between application on same host
* 30 ms between application on distinct host, same LAN


  
Done:
* auto discovery of player, first player present is the 'master'
* Send master current planet/star configuration to new players
* Player position/speed/accelerations are replicates on each other players
* Star destructions are replicates
* Keyboard textual input are sending/display on all other player
* Multicast for winxp, win 7 ok, withe 1.3p362, (Linux to be checked)

TODO:
* start/end/restart game 
* introduction, help
* transmition of game parameter to all (nb star, coefs...), current version need
  to be exactly identique for each gamer
* display list of current players, with gamer name


Inspiration
===========

Demo of gosu
Raster file came directly from these.
Code is remasterised a lot

http://regisaubarede.posterous.com/tag/game

Physics
=======
Newton law ( F=K.M.m/Dist**2 ) give a gameplay too reactive, so I use my own gravity version :)
Linear low attraction : ( F=K.M.m/Dist ) give a gameplay too smoth.

so i used : F=max( Newton law, Linear law), this give realism when planet is closed, smooth mouvement
when spaceship is far away of all planet.

Requirement
===========

Git,Ruby, gosu

```
 install ruby 1.9.X
 > gem install ang
 > ang

 or
 > git clone http://github.com/raubarede/ang.git
 > cd ang
 > ruby main.rb
 > cd net 
 > ruby multicast_test.rb &
 > ruby agent.rb
```
