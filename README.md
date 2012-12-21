dotgraph
========

javascript DiGraph class that implements the graphviz dot layout algorithm (and other goodies)

Compile with `coffee -bc js/` or if you are developing, `coffee -bc --watch js/` to have dotgraph
automatically compile every time files are saved.

Basic Usage
-----------

	g=new DiGraph([['a','e'],['a','f'],['a','b'],['e','g'],['f','g'],['b','c'],['c','d'],['d','h'],['g','h']])

