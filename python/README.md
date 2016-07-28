pytst 1.00 README
=================

© Nicolas Lehuen 2004-2005\
This work is released under the LGPL license - see the LICENSE file for
more information.

Note
----

As of 2005/12/30, this documentation is a bit outdated. I'll try to
refresh it now that the API is stabilized...

Introduction
------------

As
[promised](http://www.lehuen.com/nicolas/index.php/2005/02/14/36-james-tauber-updated-python-trie-implementation),
I've released a very preliminary version of pytst, a [Ternary Search
Tree](http://www.nist.gov/dads/HTML/ternarySearchTree.html) (TST or
trie) implementation in C++ with a Python interface (built with
[SWIG](http://www.swig.org/)). Download it
[here](http://nicolas.lehuen.com/download/pytst/) if you dare !

Basically, it behaves like a dictionary, but the keys can only be plain
strings (sorry, not Unicode strings yet). So why bother ? Because TSTs
are a lot smarter than dictionaries when it comes to :

-   Prefix-matching : find the longest entry in the TST which is a
    prefix to a given string. Handy for things like scanners, [url
    matchers](http://www.myelin.co.nz/post/2005/2/28/#200502281) and
    so on.
-   Scanning (corollary of the previous one) : using the
    [Aho-Corasick](http://www-sr.informatik.uni-tuebingen.de/%7Ebuehler/AC/AC.html)
    algorithm, you can implement pretty efficient scanners with a TST.
    The good thing it that it can scale up to tens of thousands of
    entries and still perform well.
-   Spelling correctors : find a set of entries which spelling is close
    to a given string. The distance used is the
    [Levenshtein](http://www.merriampark.com/ld.htm) distance.

I have been using this package in production for nearly a year now,
without any problem (except a surprise due to SWIG directors when I
switched to Python 2.4, but this is fixed now). I release this under the
LGPL. Incidentally, this is my first release under a license, up until
now I was pretty much releasing my dirty works in the public domain
where it could safely be ignored :). I am NOT satisfied with the
packaging (especially the tests), the code layout (it's been so long I
had not been writing C++ that I forgot a whole bunch of coding
conventions) and so on, but I decided to release this as is, and see
what happens.

Requirements and installation
-----------------------------

First of all, get the files in the
[download](http://nicolas.lehuen.com/download/pytst/) directory. If
you're lucky, there is a binary installer right for you environment (I
usually provide builds for Win32). If not, you're going to build the
module from the sources.\
\
pytst is a standard Python module, with a classic <span
style="font-family: monospace;">setup.py install</span> installation
procedure. However, the native part of the module is written in C++, so
your mileage may vary. I have successfully built the module on those
environments :\

-   Python 2.3 + MinGW (GCC 3.4.x) + Windows XP. See
    [here](http://sebsauvage.net/python/mingw.html) for more information
    on building native modules in this environment.
-   Python 2.3 + GCC 3.3.x under Cygwin + Windows XP.
-   Python 2.4 + Microsoft Visual Studio 2003 + Windows XP.
    Theoretically, using the free [Microsoft Visual C++ Toolkit
    2003](http://msdn.microsoft.com/visualc/vctoolkit2003/) should be
    possible, following [those
    instructions](http://www.vrplumber.com/programming/mstoolkit/).

If you manage to build pytst on any other environment, send me a mail so
that I can add it to this list ! Even better, we could add the binaries
to the downloads directory.\

Running the tests
-----------------

Well, for now, the test are really crappy. I only have one script using
<span style="font-family: monospace;">unittest</span>, the other ones
don't say anything  about the test passing or failing. So for now,
forget about running the test and go straight to the...\

Ternary Search Tree crash course
--------------------------------

OK, so first, the basics :\

    >>> import tst
    >>> t = tst.TST()
    >>> t['foo']='bar'
    >>> print t['foo']
    bar
    >>> print t['fo']
    None
    >>> t['foo']='baz'
    >>> print t['foo']
    baz
    >>> print t[1]
    Traceback (most recent call last):
     File "<stdin>", line 1, in ?
     File "tst.py", line 354, in __getitem__
     def __getitem__(*args): return _tst.TST___getitem__(*args)
    TypeError: argument number 2: a 'char *' is expected, 'int(1)' is received

A TST instance behaves a bit like a Python <span
style="font-family: monospace;">dict</span>, but the keys can only be
strings, more precisely <span style="font-family: monospace;">str</span>
instances. Sorry, Unicode is not supported now, mostly because I haven't
found a way yet to have SWIG handle Unicode. If  you want to use Unicode
strings as keys, you have to consistently encode them before storing
them, preferably in UTF8 since it has the nice property of not breaking
the measurement of Levenshtein distances :\

    >>> import tst
    >>> t = tst.TST()
    >>> t[u'café'.encode('UTF8')]='java'
    >>> print t[u'café'.encode('UTF8')]
    java
    >>> print t['caf\xc3\xa9']
    java
    >>> print t[u'café']
    (the process dies unexpectedly)

Talk about a crash course (wink wink, nudge nudge). Oh, yes, it's dirty,
but the nice thing about the process being killed is that it saves you
from the mess that would result of mixing byte strings and Unicode
strings in the same TST.\
\
So, what have we learned so far ? pytst is a kind of dictionary, which
handles string keys only, and crash in a not so nice way when given
Unicode strings. However, if you read the introduction carefuly, you
know that there is more to ternary search trees than this.\

Using a TST to tokenize a string\
---------------------------------

The first usage you can make of a ternary search tree is to use it to
tokenize a string. Why would you use a TST when you could use one of the
thousand lexers you can find on the Internet ? Well, try building a
ruleset for your favorite lexer with a thousand different token
definitions. Now try this with ten thousands, a hundred thousands, a
million token definition. The lexer will explode, whereas a TST will
not.\
\
Clearly, the features of the TST scanning algorithm are much less
flexible (don't try to compare them to what you can do with regular
expressions, for example), but it scales a lot well. Why would you want
to handle a million different token definition ? Well, that's up to you,
but DNA sequences parsing comes to mind.\
\
How does the scanning algorithm scales ? Well, like the
[Aho-Corasick](http://www-sr.informatik.uni-tuebingen.de/%7Ebuehler/AC/AC.html)
algorithm. The algorithm reads each character from the input string only
once, then does its little dance within the TST data structures. Believe
me, this is fast, [as described
here](http://www.lehuen.com/nicolas/index.php/2005/04/06/48-pytst-performance).\
\
Now let's see a little bit of code. You initialize the TST with all the
tokens you are looking for, then launch the scan :\

    >>> import tst
    >>> t = tst.TST()
    >>> t['1234']='token 1'
    >>> t['123456']='token 2'
    >>> t['45678']='token 3'
    >>> t['5678910']='token 4'
    >>> result = t.scan('1234561234567891012345',tst.TupleListAction())
    >>> print result
    [('123456', 6, 'token 2'), ('123456', 6, 'token 2'), ('78910', -5, None), ('1234', 4, 'token 1'), ('5', -1, None)]

The tokenizing algorithm is greedy : it will try to produce the longest 
tokens available, consuming the characters as they come. That's why the
token 4 was not produced in the above example : the sequence <span
style="font-family: monospace;">'123456'</span> was already consumed.
This may be a big limitation for some usages ; it means that the
patterns you are looking for can only be recognized from their prefix,
not from their suffix. ( Maybe that's not how ribosoms parse the DNA
(more exactly, the
[mRNA](http://www.cytochemistry.net/Cell-biology/ribosome.htm)), so this
limitation may render the algorithm useless for DNA sequence analysis,
after all. Anyway... )\
\

The <span style="font-family: monospace;">TupleListAction</span> callback class
-------------------------------------------------------------------------------

What about <span
style="font-family: monospace;">tst.TupleListAction()</span> ? This is
our first example of giving a callback to the TST so that it can perform
an action each time a match is found. TupleListAction just accumulate
all the matches in a list, each match being stored as a tuple. The first
item of the tuple is either a key from the TST, or a substring from the
scanned string. If it is a key, this means a match has been found, so
the second item is the key length and the third item is the object
associated to the key in the TST. If the first item is a substring from
the scanned string, the second item is the substring length with a
negative sign, and the third item is None. Typically, the result object
can be used like this :\

    >>> import sys
    >>> for matched_string, matched_length, matched_object in result:
    ...   if matched_length>0:
    ...      sys.stdout.write(matched_object)
    ...     else:
    ...        sys.stdout.write(print matched_string)
    ... else:
    ...  print
    token 2token 278910token 15

Here you are, you have built a transcriber that could handle millions of
transcribing rules very efficiently.  Well, that's not totally true,
since you first have to parse the string to obtain a list of tokens,
then iterate on the list of tokens to write something. Why not produce
the output while we're scanning the input string ? That's why the tst
module has other action callbacks.\

The <span style="font-family: monospace;">CallableAction</span> callback class
------------------------------------------------------------------------------

<span style="font-family: monospace;"></span>

    >>> def mycallback(key,length,obj):
    ...     if length>0:
    ...     sys.stdout.write(obj)
    ...     else:
    ...     sys.stdout.write(key)
    ...
    >>> def myresult():
    ...     print
    ...
    >>> t.scan('1234561234567891012345',tst.CallableAction(mycallback,myresult))
    token 2token 278910token 15

The <span style="font-family: monospace;">CallableAction</span> callback
class allows you to pass two callables : the first one is called for
each match or non-match, with exactly the same arguments as the one that
were found in the tuples built by <span
style="font-family: monospace;">TupleListAction</span>. The second one
is called at the end of the scan, without any arguments. Its return
value is returned by the <span
style="font-family: monospace;">scan</span> method, which allows you to
write shortcuts like :\

    >>> class Counter(object):
    ...     def __init__(self):
    ...      self.counter = 0 
    ...    def hit(self,key,length,obj):
    ...         if length>0:
    ...          self.counter += 1
    ...    def result(self):
    ...        return 'I found %i hits'%self.counter
    ...
    >>> c = Counter()
    >>> print t.scan('1234561234567891012345',tst.CallableAction(c.hit,c.result))
    I found 3 hits

You can even subclass <span
style="font-family: monospace;">tcc.CallableAction</span> for more
compacity. For example, you could reimplement <span
style="font-family: monospace;">TupleListAction</span> like this :\

    >>> class MyTupleListAction(tst.CallableAction):
    ...   def __init__(self):
    ...      tst.CallableAction.__init__(self,self.callback,self.result)
    ...      self.list = []
    ...   def callback(self,key,length,obj):
    ...       self.list.append((key,length,obj))
    ...   def result(self):
    ...        return self.list
    ...
    >>> print t.scan('1234561234567891012345',MyTupleListAction())
    [('123456', 6, 'token 2'), ('123456', 6, 'token 2'), ('78910', -5, None), ('1234', 4, 'token 1'), ('5', -1, None)]

Of course this version is less efficient than the original <span
style="font-family: monospace;">tst.TupleListAction</span> which saves
one or two layer of wrappers by going directly from the TST C++ API to
the Python C API.\

The <span style="font-family: monospace;">DictAction</span> and <span style="font-family: monospace;">ListAction</span> callback classes
----------------------------------------------------------------------------------------------------------------------------------------

TBD...\

