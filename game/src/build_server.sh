#!/bin/sh

mkdir units_srv
rm units_srv/*

fpc -CX -XX -O3 -Mdelphi -FUunits_srv -Fualib -Fumg_core -Fumg_logic -Fumg_server -FE.. -dBGR -dmgnet_tcp maxg_gs.dpr

