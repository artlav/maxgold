#!/bin/sh

mkdir units_both
rm units_both/*

PP="-Mdelphi -CX -XX -O3 -FUunits_both -Fualib -Fumg_core -Fumg_logic -Fumg_server -Fumg_graph -Fumg_menus -dBGR -dmgnet_rob -dlinkdirect "

fpc       $PP maxg.dpr -o../maxg_both
