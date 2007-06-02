#!/bin/sh
# $Id: apply.sh,v 1.2 2007/06/02 05:17:31 deraugla Exp $

ARGS1=
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
if test "$2" = "camlp4r" -o "$2" = "camlp4"; then
	COMM="../boot/$2 -nolib -I ../boot -I ../etc"
	shift; shift
	ARGS2=`echo $* | sed -e "s/[()*]//g"`
else
	COMM="../boot/camlp4 -nolib -I ../boot -I ../etc pa_o.cmo"
	ARGS2=
fi

OTOP=../..
echo ocamlrun $COMM $ARGS1 $ARGS2 $FILE 1>&2
ocamlrun $COMM $ARGS1 $ARGS2 $FILE
