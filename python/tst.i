/* 
 # $Id$
 # Copyright (C) 2004-2005 Nicolas Lehuen <nicolas@lehuen.com>
 #
 # This library is free software; you can redistribute it and/or
 # modify it under the terms of the GNU Lesser General Public
 # License as published by the Free Software Foundation; either
 # version 2.1 of the License, or (at your option) any later version.
 #
 # This library is distributed in the hope that it will be useful,
 # but WITHOUT ANY WARRANTY; without even the implied warranty of
 # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 # Lesser General Public License for more details.
 #
 # You should have received a copy of the GNU Lesser General Public
 # License along with this library; if not, write to the Free Software
 # Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
/* %module(directors="1") tst */
%module tst

%apply (char *STRING, int LENGTH) { (char *string, int string_length) };

%{
#include "pythonTST.h"
%}

%exception {
    try { $action }
    catch (TSTException e) { PyErr_SetString(PyExc_RuntimeError,e.message); SWIG_fail;}
}

%include "tst.h"

%template(_TST)         tst<char,PyObject*>;
%template(_Action)      action<char,PyObject*>;
%template(_Filter)      filter<char,PyObject*>;
%template(_Serializer)  serializer<char,PyObject*>;

%include "pythonTST.h"
