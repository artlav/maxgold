## Description

This is a from-scratch rewrite of Interplay's 1996 game M.A.X.

Project's former home and the old Russian M.A.X. club museum: [http://www.rumaxclub.ru](http://www.rumaxclub.ru)

I am no longer able to maintain the code or am interested in it, so it's provided here as is.

## Project history

 * Rumaxclub formed by Sadov S.V. in 1998
 * M.A.X. "Gold" idea formulated by 2000
 * Functional version written by Artlav in VB in 2003
 * Rewritten in Pascal in 2004
 * Extensively worked on and played over the 00s by the club
 * Died in 2014
 * Raised from the dead and rewritten into a client-server model in 2015
 * Died in 2016
 * Raised from the dead and cleaned up in 2019

## Code rationale

The code was more or less written along with me learning to program, and most of it was done before i had the wisdom to use standard libraries or make modular components.

As a consequence, the code have no dependencies above the OS, and at some point even included the OS and could run on bare hardware. Most of this is redundant for a game, and was never removed.

Another consequence is that despite several attempts to clean up and rewrite it, the code is still a mess and the graphics part contains a bunch of global variables. The server part was more or less cleaned up, but is still far from perfect.

## Code aesthetics

I do like object oriented programming but hate Borland's syntax for it with a fiery passion. Which is why the code contains many things that look like objects, but never use the syntax.

The language used is my own dialect of Pascal, basically "C with dynamic arrays".

## Cleaning up involved

 * Removed update server. I can't maintain one, so someone would have to add a new one if needed, and write support for it.
 * Removed VFS and ability to have packed resources. This is an OS-grade component that have no use in a game.
 * Removed Android version. Needs the VFS ability and a lot of extra tooling, no one ever used it anyway.
 * Removed sound support. Someone should really rewrite it to use some standard library, ok? That part was too horrible to publish.

## Code structure

 * There is a server and a client, they talk over some sort of a network.
 * There is a common logic library that implements all the basic operations of the game. It's partially shared between the client and the server. The client uses the same routines the server does in order to predict the replies of the server and do smooth animations and actions.
 * The server does all the gameplay calculations.
 * A save game is a sequence of all the actions performed.
 * A replay is the sequence of all the responses the client received.
 * Most actions are stateless, so you can try any operation without committing.
 * The alib is a slice of the implementus-everythingus library i have, trimmed down to the code only used by the game.
 * Convert and map_gen contains various scraps of code to convert the old M.A.X. file formats and to generate maps. Provided as is.

## Assets

 * The assets are not provided as i'm not aware of what their copyright situation is. The original game is technically abandoneware, but who knows.
 * You can reconstruct them from max.res file of your copy of the original game, or look for people from the old club for help.

## Compilation

 * Install Free Pascal, run one of build.sh files.
 * There are three modes: Client, server and client+server.
