SRCDIR=js
PEGJS=pegjs

all: dotparser.js libs

dotparser.js: 
	$(PEGJS) --export-var "DotParser" $(SRCDIR)/graphviz-dot-grammar.pegjs $(SRCDIR)/dotparser.js
	cat $(SRCDIR)/graphviz-dot-preparser.js >> $(SRCDIR)/dotparser.js
libs:
	coffee -bc $(SRCDIR)/
