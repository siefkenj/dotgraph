dotgraph
========

javascript parser and library for the Graphviz dot/xdot format, implimented
based on the grammar defined http://www.graphviz.org/doc/info/lang.html provides
a parser based on PEG.js and some javascript objects for manipulating and 
querying graph properties.


Basic Usage
-----------

	ast = DotParser.parse(str_source);
	graph = new DotGraph(ast);
	graph.walk(); 	// walks the ast and gathers all information about nodes, edges, and subgraphs

	console.log(graph.nodes); 	// object of all nodes and their attrs
	console.log(graph.edges); 	// object of all edges and their attrs
	console.log(graph.graphs); 	// object of all subgraphs and their attrs

`XDotGraph` is a subclass of `DotGraph` that parses all the recognized xdot attributes and turns
them into javascript objects, automatically converting inches to pixels where applicable.
Note: the list of recognized attributes is currently very short, consisting of `pos` (for
nodes and edges), `width`, `height`, `bb`, `lp`

