ANG : spacial navigation micro-game
==================================

Navigate in space, pursuite some star and use planet gravity to
navigate.

In developpement,
Working, but missing menu, setup, level choice ....


Free to use, modify and distribute.


* multicast between all member on LAN
* not ready ! fro naow, only play all ship on all game instance
Multi gamer
===========
News : in net directory, begining a ang version  multi-player on local network,
use Multicast (so work only on LAN).
The game : same as ang, but all players must collaborate for destroy a 
maximum of stars.

Usage:
  > angm

Done:

* auto disovery of player, first player present is the 'master'
* send mastr current configuratin to all new player
* player position/speed/accelerations are replicates on each other players
* star destruction are replicate
* keyboard textual input are sending/display on all other player

TODO:
* global score
* a game with start, end, score
* list of current players


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