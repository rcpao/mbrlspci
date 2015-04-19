#! /usr/bin/awk -f

# ASAP - AWK Simple and Awful Preprocessor
# Copyright (C) 2007 Matous Jan Fialka
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU general Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU general Public License for
# more details.
#
# You should have received a copy of the GNU general Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.



# TODO: MACROS
# TODO:	  #eval
# TODO:	  #if #ifnot #elif #elifnot
# TODO:	  #ifdef #ifndef #elifdef #elifndef
# TODO:	  #else #endif



# MACROS:
#
# <macroline> ::= "#include" <value>			|
#		  "#pragma <variable>			|
#		  "#eval" { <macroline> | value }	|
#		  "#define" <variable> [ <value> ]	|
#		  "#undef" <variable>			|
#		  "#if" { <variable> | <number> }	|
#		  "#ifnot" { <variable> | <number> }	|
#		  "#elif" <variable> | <number>		|
#		  "#elifnot" { <variable> | <number> }	|
#		  "#ifdef" <variable>			|
#		  "#ifndef" <variable>			|
#		  "#elifdef" <variable>			|
#		  "#elifndef" <variable>		|
#		  "#else"				|
#		  "#endif"				|
#		  "#return"				|
#		  "#quit"				|
#		  "#echo" [ <value> ]			|
#		  "#warning" [ <value> ]		|
#		  "#error" <value>			;
#
#
#
# POSIX 1003.2 REGULAR EXPRESSIONS:
#
# <variable>  ::= REGEX "^([_]*)?[a-zA-Z][0-9_a-zA-Z\-]*$"
# <number>    ::= REGEX "^[\-]?[0-9]+$"
# <value>     ::= REGEX "^.*$"
#
#
#
# PRAGMA DIRECTIVES:
#
# strict      - #include produces non-critical errors too
# once        - #include includes each filename only once
#
#
#
# BUILTIN VARIABLES:
#
# __ARGC__    - argument count
# __ARGN__    - argument number
# __ARGV__    - argument value
# __FILE__    - filename
# __LINE__    - file line number
# __DATA__    - file line data
# __EXIT__    - exit code



BEGIN {
	FSTDIN		= "/dev/fd/0"
	FSTDOUT		= "/dev/fd/1"
	FSTDERR		= "/dev/fd/2"

	FSTDWARN	= FSTDERR

	NULL		= ""
	LFNL		= "\n"

	ERR[1]		= "no such file or directory"
	ERR[130]	= "#include output descriptor on input"
	ERR[131]	= "#include standard input overflow"
	ERR[132]	= "#include target already included"
	ERR[133]	= "#include no such file or directory"
	ERR[140]	= "#pragma directive syntax error"
	ERR[150]	= "#define variable syntax error"
	ERR[151]	= "#define read-only variable"
	ERR[160]	= "#undef variable syntax error"
	ERR[161]	= "#undef read-only variable"

	PRA["strict"]	= 0
	PRA["once"]	= 0

	DEF["__ARGV__"] = 1
	DEF["__ARGC__"] = 1
	DEF["__ARGN__"] = 1
	DEF["__ARGD__"] = 1
	DEF["__FILE__"]	= 1
	DEF["__LINE__"]	= 1
	DEF["__DATA__"]	= 1
	DEF["__EXIT__"]	= 1

	VAR["__ARGV__"] = ajoin(ARGV, " ")
	VAR["__ARGC__"] = ARGC
	VAR["__ARGN__"] = 0
	VAR["__ARGD__"] = NULL
	VAR["__FILE__"]	= FSTDIN
	VAR["__LINE__"]	= 0
	VAR["__DATA__"]	= NULL
	VAR["__EXIT__"] = minclude(DEF, VAR, PRA)

	exit
}



END {
	exit die(VAR)
}



function die(vars)
{
	if(vars["__EXIT__"] > 254) {

		printf "User error (%s: %d): %s" LFNL,
			vars["__FILE__"], vars["__LINE__"], 
			ERR[vars["__EXIT__"]] >> FSTDERR
	}
	else if(vars["__EXIT__"] > 127) {

		printf "*** [%s]" LFNL, vars["__DATA__"] >> FSTDERR
		printf "Runtime error (%s: %d): %s" LFNL,
			vars["__FILE__"], vars["__LINE__"], 
			ERR[vars["__EXIT__"]] >> FSTDERR
	}
	else if(vars["__EXIT__"] > 1) {

		printf "Syntax error (%d/ %d): %s" LFNL,
			vars["__ARGN__"], vars["__ARGC__"],
			ERR[vars["__EXIT__"]] >> FSTDERR
	}
	else if(vars["__EXIT__"] > 0) {

		printf "Error: %s" LFNL,
			ERR[vars["__EXIT__"]] >> FSTDERR
	}

	return vars["__EXIT__"]
}



function minclude(d, v, p , f, n, c, i , m, a, t, j, q)
{
	if(fisstdout(v["__FILE__"]) || fisstderr(v["__FILE__"])) {

		v["__FILE__"] = apop(f)
		v["__LINE__"] = apop(n)
		v["__DATA__"] = apop(c)

		merror(v, 130)
	}

	if(ahasfstdin(i) && (fisstdin(v["__FILE__"]))) {

		if(p["strict"]) {

			v["__FILE__"] = apop(f)
			v["__LINE__"] = apop(n)
			v["__DATA__"] = apop(c)

			merror(v, 131)
		} else
			return 0
	}

	if(ahas(i, v["__FILE__"])) {

		if(p["once"]) {

			if(p["strict"]) {

				v["__FILE__"] = apop(f)
				v["__LINE__"] = apop(n)
				v["__DATA__"] = apop(c)

				merror(v, 132)
			} else
				return 0
		} else
			close(v["__FILE__"])
	}

	v["__LINE__"] = 0
	v["__DATA__"] = NULL

	if(fexists(v["__FILE__"])) {

		if(! ahas(i, v["__FILE__"]))
			apush(i, v["__FILE__"])

		j = 0

		while((getline v["__DATA__"] < v["__FILE__"]) > 0) {

			v["__LINE__"]++

			if((v["__DATA__"] ~ /^[ \t]*#.*[^\\]?\\$/) || \
			  ((v["__DATA__"] ~ /^.*[^\\]?\\$/) && j)) {

				v["__DATA__"] = substr(v["__DATA__"], 1,
				       length(v["__DATA__"]) - 1)

				apush(q, chopstrl(v["__DATA__"]))

				j = 1

				continue
			}

			if(! aempty(q)) {

				if(j)
					apush(q, chopstrl(v["__DATA__"]))

				v["__DATA__"] = ajoin(q, NULL)

				delete q

				j = 0
			}

			if(v["__DATA__"] ~ /^[ \t]*\\?\\#/) {

				munquote(d, v)

				printf "%s" LFNL, meval(d, v) >> FSTDOUT
			}
			else if(v["__DATA__"] ~ /^[ \t]*#include[ \t]+/) {

				apush(f, v["__FILE__"])
				apush(n, v["__LINE__"])
				apush(c, v["__DATA__"])

				v["__DATA__"] = chopstr(shift(1, v["__DATA__"]))
				v["__FILE__"] = meval(d, v)
				v["__EXIT__"] = minclude(d, v, p, f, n, c, i)
				v["__FILE__"] = apop(f)
				v["__LINE__"] = apop(n)
				v["__DATA__"] = apop(c)

				if(v["__EXIT__"])
					merror(v, 133)
			}
			else if(v["__DATA__"] ~ /^[ \t]*#pragma[ \t]+/) {

				a = chopstr(shift(1, v["__DATA__"]))

				if(! visvalid(a))
					merror(v, 140)

				mpragma(p, a)
			}
			else if(v["__DATA__"] ~ /^[ \t]*#define[ \t]+/) {

				a = chopstr(shift(1, v["__DATA__"]))
				t = shift(1, a)
				a = substrto(" ", a)

				if(! visvalid(a))
					merror(v, 150)

				if(visreadonly(a))
					merror(v, 151)

				mdefine(d, v, a, t)
			}
			else if(v["__DATA__"] ~ /^[ \t]*#undef[ \t]+/) {

				a = chopstr(shift(1, v["__DATA__"]))

				if(! visvalid(a))
					merror(v, 160)

				if(visreadonly(a))
					merror(v, 161)

				mundef(d, v, a)
			}
			else if(v["__DATA__"] ~ /^[ \t]*#return$/) {

				break
			}
			else if(v["__DATA__"] ~ /^[ \t]*#quit$/) {

				merror(v, 0)
			}
			else if(v["__DATA__"] ~ /^[ \t]*#echo[ \t]+/) {

				mecho(v, chopstr(shift(1, v["__DATA__"])))
			}
			else if(v["__DATA__"] ~ /^[ \t]*#warning[ \t]+/) {

				mwarning(v, chopstr(shift(1, v["__DATA__"])))
			}
			else if(v["__DATA__"] ~ /^[ \t]*#error[ \t]+/) {

				ERR[255] = chopstr(shift(1, v["__DATA__"]))

				merror(v, 255)
			}
			else if(v["__DATA__"] ~ /^[ \t]*#/) {
			}
			else {
				printf "%s" LFNL, meval(d, v) >> FSTDOUT
			}
		}

		close(v["__FILE__"])
	} else
		return 1

	return 0
}

function munquote(defs, vars)
{
	vars["__DATA__"] = gensub(/^([ \t]*\\?)\\(.*)/, "\\1\\2", NULL,
		vars["__DATA__"])

	return vars["__DATA__"]
}

function meval(defs, vars , m, x, d, a, i, l, r)
{
	if(m != NULL) {

		split(vars["__DATA__"], a, m)

                l = alength(a)
		r = NULL

                if(l > 0) {

                	for(i = 1; i < l; ++i) {

                        	r = r a[i]

                        	if(a[i] ~ /\\+$/) {

                                	gsub(/\\$/, NULL, r)

                                	r = r m
                        	}
				else {
                                	if(mifdef(defs, m))
						r = r vars[m]
					else
						r = r m
				}			
                	}

                	r = r a[l]
                }

		vars["__DATA__"] = r
	}
	else {
		l = asortil(defs, x)

		for(i = l; i > 0; i--)
			vars["__DATA__"] = meval(defs, vars, x[i])
	}

	return vars["__DATA__"]
}

function mpragma(pras, pra , i)
{
	for(i in pras)
		if(i == pra)
			return (++pras[i])

	return 0
}

function mdefine(defs, vars, v , a)
{
	defs[v] = 1
	vars[v] = ((a == NULL) ? 1 : a)

	return vars[v]
}

function mundef(defs, vars, v)
{
	delete vars[v]
	delete defs[v]
	return
}

function mifdef(defs, v)
{
	return (defs[v] == 1)
}

function mecho(vars, echo)
{
	printf "%s" LFNL,
		echo >> FSTDWARN
	return
}

function mwarning(vars, warning)
{
	printf "Warning (%s: %d): %s" LFNL,
		vars["__FILE__"], vars["__LINE__"], 
		warning >> FSTDWARN
	return
}

function merror(vars, err)
{
	vars["__EXIT__"] = err

	exit
}



function visvalid(a)
{
	return (a ~ /^([_]*)?[a-zA-Z][0-9_a-zA-Z\-]*$/)
}

function visreadonly(a)
{
	return (a ~ /^__(ARG(V|C|N|D)|FILE|LINE|DATA|EXIT)__$/)
}



function shift(number , text, separator, array)
{
        if(number == NULL || number <= 0)
                number = 1

        if(separator == NULL)
                separator = FS

        if(separator == " ")
                separator = "[ \t]+"

        while(number-- > 0) {

		sub("^" separator, NULL, text)

                if(split(text, array, separator) < 2) {

                        text = NULL 

                        break
                } else
                        text = substr(text, match(text, separator) + RLENGTH)
        }

        return text
}

function chopstrl(text)
{
	gsub(/^[ \t]+/, NULL, text)

	return text
}

function chopstrr(text)
{
	gsub(/[ \t]+$/, NULL, text)

	return text
}

function chopstr(text)
{
	return chopstrl(chopstrr(text))
}

function substrto(pattern, text)
{
	if(pattern == " ")
		pattern = "[ \t]+"

        sub(pattern ".*", NULL, text)

        return text
}



function aempty(array , i)
{
        for(i in array)
                return 0

        return 1
}

function alength(array , len, i)
{
        if(!aempty(array)) {

                len = 0

                for(i in array)
                        len++

                return len
        } else
                return 0
}

function apush(array, value , i)
{
        array[alength(array) + 1] = value

        return value
}

function apop(array, i , r)
{
        if(!aempty(array)) {

                i = alength(array)
                r = array[i]

                delete array[i]
                return r
        } else
                return NULL
}

function ajoin(array, sep , x, r, l)
{
	l = alength(array)

	if(l)
		for(x = 1; x <= l; ++x)
			r = r ((r != NULL) ? sep : NULL) array[x]

	return r
}

function ahas(array, v , i)
{
	for(i in array)
		if(array[i] == v)
			return 1

	return 0
}

function asortil(a, t , i, j)
{
        j = 1

        for(i in a)
                t[j++] = i

        return asortl(t)
}

function asortl(a, i , l, j, t)
{
        l = alength(a)

        for(i = 2; i <= l; ++i) {

                for(j = i; length(a[j - 1]) > length(a[j]); --j) {

                        t = a[j]
                        a[j] = a[j - 1]
                        a[j - 1] = t
                }
	}

        return l
}

function ahasfstdin(array , i)
{
	for(i in array)
		if(fisstdin(array[i]))
			return 1

	return 0
}



function fexists(file , line)
{
        if(fisstdin(file))
                return 1

        if((getline line < file) > 0) {

                close(file)

                return 1
        }

        return 0
}

function fisstdin(file)
{
        if(file == "-" ||
           file == "/dev/tty" ||
           file == "/dev/stdin" ||
           file == "/dev/fd/0" ||
           file == "/proc/self/fd/0")
                return 1

        return 0
}

function fisstdout(file)
{
        if(file == "/dev/stdout" ||
           file == "/dev/fd/1" ||
           file == "/proc/self/fd/1")
                return 1

        return 0
}

function fisstderr(file)
{
        if(file == "/dev/stderr" ||
           file == "/dev/fd/2" ||
           file == "/proc/self/fd/2")
                return 1

        return 0
}
