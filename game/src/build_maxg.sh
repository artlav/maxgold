#!/bin/sh

mkdir units
rm units/*

PP="-Mdelphi -CX -XX -O3 -FUunits -Fualib -Fumg_core -Fumg_logic -Fumg_server -Fumg_graph -Fumg_menus -dBGR -dmgnet_tcp "

fpc       $PP maxg.dpr -o../maxg
