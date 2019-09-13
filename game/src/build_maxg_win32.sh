#!/bin/sh

mkdir units
rm units/*

PP="-Mdelphi -CX -XX -O3 -FUunits -Fualib -Fumg_core -Fumg_logic -Fumg_server -Fumg_graph -Fumg_menus -dBGR -dmgnet_tcp "

fpc_win32 $PP -WG maxg.dpr -o../maxg_win32.exe
