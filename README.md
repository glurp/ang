ANG : spacial navigation micro-game
==================================

Navigate in space, pursuite some star and use planet gravity to
navigate.

In developpement,
Working, but missing menu, setup, level choice ....


Free to use, modify and distribute.


Multi gamer
===========


In net directory, a ang game, version  multi-player on local network,
use Multicast (so work only on LAN).

The game : same as ang, but all players must collaborate for destroy a 
maximum of stars.

Usage:
  > angm

Done:
* auto discovery of player, first player present is the 'master'
* Send master current planet/star configuration to new players
* Player position/speed/accelerations are replicates on each other players
* Star destructions are replicates
* Keyboard textual input are sending/display on all other player
* Multicast for winxp, win 7 ok, with 1.3p362, (Linux to be checked)

TODO:
* start/end/restart game 
* introduction, help
* transmition og game parameter to all (nb star, coefs...), current version need
  to be exactly identique for each gamer
* display list of current players, with name


Inspiration
===========

Demo of gosu
Raster file came directly from these.
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