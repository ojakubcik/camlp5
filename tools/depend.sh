#!/bin/sh
# $Id: depend.sh,v 1.3 2007/07/11 12:01:39 deraugla Exp $

ARGS1="pr_depend.cmo --"
FILE=
while test "" != "$1"; do
	case $1 in
	*.ml*) FILE=$1;;
	*) ARGS1="$ARGS1 $1";;
	esac
	shift
done

head -1 $FILE >/dev/null || exit 1

set - `head -1 $FILE`
if test "$2" = "camlp5r" -o "$2" = "camlp5"; then
	WHAT="$(echo $2 | sed -e "s/camlp5/$NAME/")"
	COMM="../boot/$WHAT -nolib -I ../boot -I ../etc"
	shift; shift
	ARGS2=`echo $* | sed -e "s/[()*]//g"`
else
	COMM="../boot/main -nolib -I ../boot -I ../etc pa_o.cmo"
	ARGS2=
fi

OTOP=../..
echo ocamlrun $COMM $ARGS2 $ARGS1 $FILE 1>&2
ocamlrun $COMM $ARGS2 $ARGS1 $FILE
