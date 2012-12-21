###
# Class to perform operations on a directed graph like
# searching for multiple paths, finding neighbors, etc.
###
class DiGraph
    constructor: (edges, nodes=[]) ->
        @nodes = {}
        @edges = []
        @forwardNeighborHash = null
        @backwardNeighborHash = null

        for n in nodes
            @nodes[n] = true
        for e in edges
            @edges.push e.slice()
            @nodes[e[0]] = true
            @nodes[e[1]] = true
    _generateForwardNeighborHash: ->
        if @forwardNeighborHash
            return

        hash = {}
        for e in @edges
            if not hash[e[0]]?
                hash[e[0]] = []
            hash[e[0]].push e[1]
        @forwardNeighborHash = hash
    _generateBackwardNeighborHash: ->
        if @backwardNeighborHash
            return

        hash = {}
        for e in @edges
            if not hash[e[1]]?
                hash[e[1]] = []
            hash[e[1]].push e[0]
        @backwardNeighborHash = hash
    # computes all the nodes in the span of edge
    edgeSpan: (node) ->
        ret = {}
        @_generateForwardNeighborHash()

        maxDepth = Object.keys(@nodes).length

        findNeighbors = (node, depth) =>
            ret = []
            if depth >= maxDepth or not node? or not @forwardNeighborHash[node]?
                return ret
            for l in @forwardNeighborHash[node]
                ret = ret.concat(findNeighbors(l, depth + 1))
            return ret.concat(@forwardNeighborHash[node])

        return findNeighbors(node, 0)

    # determines if there is a path between e1 and e2
    isPath:(n1, n2) ->
        return @edgeSpan(n1).indexOf(n2) != -1 or @edgeSpan(n2).indexOf(n1) != -1

    # looks at all the ancestors of node and sees if there are alternative,
    # longer routes to node.  If so, it deletes the edge between node and
    # the anscestor.
    #
    # return the number of edges deleted
    eliminateRedundantEdgesToNode: (node) ->
        @_generateBackwardNeighborHash()
        @_generateForwardNeighborHash()
        ancestors = @backwardNeighborHash[node] || []

        for n in ancestors
            span = @edgeSpan(n)
            spanHash = {}
            for s in span
                spanHash[s] = true
            for s in ancestors
                # we want to loop through all of our siblings that aren't us
                if s == n
                    continue
                # if we can get from n -> s and we know there is an edge from s -> node, 
                # then we can safely delete the edge n -> s
                if spanHash[s]
                    @removeEdge([n,node])
                    return 1 + @eliminateRedundantEdgesToNode(node)
        return 0

    # eliminates short paths to between nodes if there is a longer path
    # connecting them
    #
    # TODO is there a more efficient way to do this?  This should be ok for small graphs but
    # bad for large ones.
    eliminateRedundantEdges: ->
        ret = 0
        for n of @nodes
            ret += @eliminateRedundantEdgesToNode(n)
        return ret

    # removes the edge edge
    removeEdge: (edge) ->
        # get a list of all the edges we're going to remove
        # we want the list to be in reverse numberial order so
        # as we splice away the edges, things work out
        indices = []
        for e,i in @edges
            if DiGraph.edgesEqual(e, edge)
                indices.unshift i
        for i in indices
            @edges.splice(i, 1)
        # these hashs are now invalid!
        @forwardNeighborHash = null
        @backwardNeighborHash = null
        
    @edgesEqual: (e1, e2) ->
        return (e1[0] == e2[0]) and (e1[1] == e2[1])

    # finds the forward neighbors of all vertices in subgraphNodes.
    # Vertices in subgraphnodes are not included in this list
    findForwardNeighborsOfSubgraph: (subgraphNodes) ->
        # ensure we are working with a dictionary
        if subgraphNodes instanceof Array
            nodes = subgraphNodes
            subgraphNodes = {}
            for n in nodes
                subgraphNodes[n] = true
        
        @_generateForwardNeighborHash()
        ret = {}
        for n of subgraphNodes
            for child in (@forwardNeighborHash[n] || [])
                if not subgraphNodes[child]
                    ret[child] = true
        return ret
    # finds the forward neighbors of all vertices in subgraphNodes.
    # Vertices in subgraphnodes are not included in this list
    findBackwardNeighborsOfSubgraph: (subgraphNodes) ->
        # ensure we are working with a dictionary
        if subgraphNodes instanceof Array
            nodes = subgraphNodes
            subgraphNodes = {}
            for n in nodes
                subgraphNodes[n] = true
        
        @_generateBackwardNeighborHash()
        ret = {}
        for n of subgraphNodes
            for child in (@backwardNeighborHash[n] || [])
                if not subgraphNodes[child]
                    ret[child] = true
        return ret
    # returns a list containing every source node
    findSources: ->
        ret = []
        @_generateBackwardNeighborHash
        for n of @nodes
            if not @backwardNeighborHash[n]
                ret.push n
        return ret

    # returns a string representing the graph in
    # graphviz dot format
    toDot: (name) ->
        ret = "digraph #{name} {\n"
        for e in @edges
            ret += "\t\"#{e[0]}\" -> \"#{e[1]}\"\n"
        ret += "\n"
        for i in [1, 2, 3, 4]
            if @years
                ret += "\tsubgraph cluster#{i} {\n"
                ret += "\t\tlabel=\"Year #{i}\"\n\t\t"
                for c in @years[i]
                    ret += "\"#{c}\"; "
                ret += "\n\t}\n"
        ret += "}"

        return ret
    ###
    # Functions for doing rankings and orderings of graphs
    # to implement the dot graph layout algorithm
    ###

    # generates a ranking such that no neighbors ranks are equal
    # and children always have a higher rank than parents
    generateFeasibleRank: (graph=this) ->
        graph._generateForwardNeighborHash()
        graph._generateBackwardNeighborHash()
        ranks = {}
        for n of @nodes
            # figure out the maximum and minimum ranks of our parents
            # and our children, so we can choose a rank between them
            min_rank = 0
            max_rank = 1
            for parent in (graph.backwardNeighborHash[n] || [])
                if ranks[parent]
                    min_rank = Math.max(ranks[parent], min_rank)
            for child in (graph.forwardNeighborHash[n] || [])
                if ranks[child]
                    max_rank = Math.min(ranks[child], max_rank)
            ranks[n] = (min_rank + max_rank) / 2
        # our ranks are floating point numbers at the moment.  
        # We need to order them and make them all integers for the
        # next part of the dot algorithm
        rankFracs = (v for k,v of ranks)
        rankFracs.sort()
        rankFracHash = {}
        for d,i in rankFracs
            rankFracHash[d] = i
        for k,v of ranks
            ranks[k] = rankFracHash[v]
        return ranks
    # given the ranks, returns the vertices of a tree
    # containing rootNode that is maximal and has the property
    # that the difference between the ranks of neighboring
    # nodes is equal to that edge's minRankDelta.
    #
    # This function assumes the graph is directed with only one source.  If
    # rootNode is set, it is assumed rootNode is a source
    findMaximalTightTree: (ranks, rootNode, graph=this) ->
        DEFAULT_DELTA = 1
        minRankDelta = graph.minRankDelta || {}

        expandTightTree = (tailNode, headNode, treeNodes={}, edges=[]) ->
            # if where we're looking has already been included in the tree,
            # we shouldn't try to grow the tree in that direction, lest we add a 
            # cycle
            if treeNodes[headNode]
                return treeNodes

            edgeDelta = minRankDelta[[tailNode, headNode]] || DEFAULT_DELTA
            # if we are a tight edge, or if we are the base case where we start with headNode==tailNode,
            # proceed to add branches to the tree
            if ranks[headNode] - ranks[tailNode] == edgeDelta or headNode == tailNode
                treeNodes[headNode] = true
                edges.push [tailNode, headNode] if tailNode != headNode
                for c in (graph.forwardNeighborHash[headNode] || [])
                    expandTightTree(headNode, c, treeNodes, edges)
            return {nodes: treeNodes, edges: edges}

        if not rootNode
            sources = graph.findSources()
            if sources.length == 0
                throw new Error("Tried to find a Maximal and Tight tree on a graph with no sources!")
        else
            sources = [rootNode]

        maximalTree = expandTightTree(sources[0], sources[0])
        return maximalTree
    
    ###
    # returns the minimum difference in ranks between
    # node and its ancestors.
    getRankDiff: (ranks, node, graph=this) ->
        graph._generateBackwardNeighborHash()
        ancestors = graph.backwardNeighborHash[node] || []
        diff = Infinity
        for n in ancestors
            diff = Math.min(diff, ranks[node] - ranks[n])
        return diff

    # returns the minimum difference in ranks among node
    # and its ancestors minus the minimum allowed rank delta
    getSlack: (ranks, node, graph=this) ->
        DEFAULT_DELTA = 1
        minRankDelta = graph.minRankDelta || {}

        graph._generateBackwardNeighborHash()
        ancestors = graph.backwardNeighborHash[node] || []
        diff = Infinity
        tail = null
        for n in ancestors
            rankDiff = ranks[node] - ranks[n] - (minRankDelta[[n,node]] || 0)
            if rankDiff < diff
                diff = rankDiff
                tail = n
        return {slack: diff, edge: [tail, node]}
    ###

    # returns an edge with one node in tree and one node not in tree
    # with the slack minimum
    getIncidentEdgeOfMinimumSlack: (ranks, tree, graph=this) ->
        DEFAULT_DELTA = 1
        minRankDelta = graph.minRankDelta || {}
        
        incidentEdges = (e for e in graph.edges when (tree[e[0]] ^ tree[e[1]])) # ^ is xor
        giveSlack = (edge) ->
            rankDiff = Math.abs(ranks[edge[0]] - ranks[edge[1]])
            return rankDiff - (minRankDelta[edge] || DEFAULT_DELTA)

        slacks = ([giveSlack(e),e] for e in incidentEdges)
        slacks.sort()
        console.log slacks, incidentEdges, tree
        return slacks[0]

    # produces a set of ranks and a feasible spanning tree
    # derived from those ranks for use in the dot algorithm
    findFeasibleSpanningTree: (graph=this) ->
        # generate a valid ranking for all the nodes.
        # This may not be tight, but we will tighten it.
        ranks = graph.generateFeasibleRank()

        sources = graph.findSources()
        if sources.length != 1
            throw new Error("Attempting to build a spanning tree, but have the wrong number of sources: #{sources.length} (#{sources})")

        # Start with a tree based at the source of the graph
        # and add nodes to it one by one, adjusting all
        # the rankings as we go so in the end, we have a feasible 
        # ranking corresponding to a tree
        tree = {}
        tree[sources[0]] = true
        for i in [1...Object.keys(graph.nodes).length]
            # first we look for an edge that we could possibly add to our tree
            # we look for one that has minimum slack and then we "translate"
            # our tree by that slack value so we can add the new edge to our tree
            # we continue doing this until we have a tree that spans every edge
            [slack, edge] = graph.getIncidentEdgeOfMinimumSlack(ranks, tree)
            
            # determine if the edge is pointed inward or outward
            edgeDirection = if tree[edge[0]] then 1 else -1
            incidentNode = if edgeDirection is 1 then edge[1] else edge[0]
            for node of tree
                # shift the established tree to eliminate the slack.  Since we chose
                # and edge with minimal slack, we always maintain feasibility
                ranks[node] += edgeDirection*slack
            # now that we have shifted all the ranks in the tree to eliminate the slack,
            # it is safe to add incidentNode to our tree
            tree[incidentNode] = true
        return {tree: tree, ranks: ranks}


