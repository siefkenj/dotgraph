###
    demo.coffee a demo of dotgraph.js/coffee
    Copyright (C) 2013  Jason Siefken

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
###

###
# Code to render a parsed xdot file as an SVG
###

renderCurrent = ->
    window.ast = DotParser.parse(document.querySelector('textarea').value)
    console.log ast
    window.graph = new DotGraph(ast)
    console.log graph
    graph.walk()

renderToSvg = (graph) ->
    floatList = (l) -> (parseFloat(v) for v in l.split(','))
    createElm = (name, attrs={}, parent) ->
        elm = document.createElement(name)
        for k,v of attrs
            elm.setAttribute(k,v)
        if parent?
            parent.appendChild(elm)
        return elm
    createElmNS = (name, attrs={}, parent) ->
        elm = document.createElementNS("http://www.w3.org/2000/svg", name)
        for k,v of attrs
            elm.setAttribute(k,v)
        if parent?
            parent.appendChild(elm)
        return elm
    window.div = createElm('div', {}, document.body)
    window.svg = createElmNS('svg', {width:700, height:500}, div)
    window.bb = createElmNS('g', {transform:"translate(0,0)"}, svg)

    parser = new DOMParser()
    for k,n of graph.nodes
        if n.attrs.pos
            pos = floatList(n.attrs.pos)

            label = n.attrs.label
            try
                label = label.replace("\\N", k)
            catch e
               ''
            if label.value
                try
                    xml = parser.parseFromString("<root>#{label.value}</root>", "text/xml")
                    label = (x.textContent for x in xml.querySelectorAll('font')).join('\n')
                catch e
                    console.log label.value
                    label = ''+label.value

            rx = parseFloat(n.attrs.width)*36
            ry = parseFloat(n.attrs.height)*36
            rect = createElmNS('rect', {id: k, x:pos[0]-rx, y:pos[1]-ry, width:rx*2, height:ry*2, stroke:'black', fill:'none', rx:10}, bb)
            g = createElmNS('g',{transform:"translate(#{pos[0]},#{pos[1]})"},bb)
            text = createElmNS('text', {x:0, y:0, 'text-anchor':'middle', 'font-family':'sans', 'font-size':12, fill:'red'}, g)
            tspan = createElmNS('tspan',{x:0,y:-5}, text)
            tspan.textContent = label.split('\n')[0]
            tspan = createElmNS('tspan',{x:0,y:12,fill:'blue'},text)
            tspan.textContent = ''+(''+label).split('\n')[1]

    for k,e of graph.edges
        e = e[0]
        if e.attrs.pos
            points = e.attrs.pos.slice(2).split(' ').map(floatList)
            path = "M #{points[1][0]} #{points[1][1]}"
            i = 2
            while i < points.length
                path += " C " + [points[i][0],points[i][1],points[i+1][0],points[i+1][1],points[i+2][0],points[i+2][1]].join(' ')
                i+=3
            createElmNS('path', {d:path, stroke:'blue', fill:'none'}, bb)



    dragging = false
    oldx = oldy = 0
    offsetx=offsety=0

    getCoords = (evt) ->
        rect = svg.getBoundingClientRect()
        return [evt.pageX-div.offsetLeft, evt.pageY-div.offsetTop]
        return [evt.clientX-rect.left, evt.clientY-rect.top]

    svg.onmousedown = (evt) ->
        [x,y] = getCoords(evt)
        oldx=x
        oldy=y
        dragging = true
    svg.onmouseup = (evt) ->
        dragging = false
        #console.log evt, arguments

    svg.onmousemove= (evt) ->
        if dragging
            [x,y] = getCoords(evt)
            diffx = x-oldx
            diffy = y-oldy
            offsetx += diffx
            offsety += diffy
            bb.setAttribute('transform', "translate(#{offsetx},#{offsety})")
            oldx = x
            oldy = y





renderDotGraph = (canvasElm, graph) ->
    floatList = (l) -> (parseFloat(v) for v in l.split(','))
    ctx = canvasElm.getContext("2d")
    ctx.fillStyle = 'white'
    ctx.rect(0,0,10000,10000)
    ctx.fill()
    ctx.fillStyle = 'black'

    ctx.strokeStyle = 'red'
    for k,g of graph.graphs
        if g.attrs.bb
            bb = floatList(g.attrs.bb)
            ctx.beginPath()
            ctx.rect(bb[0],bb[1],bb[2]-bb[0],bb[3]-bb[1])
            ctx.stroke()
    ctx.textAlign = 'center'
    ctx.textBaseline = 'middle'
    for k,n of graph.nodes
        if n.attrs.pos
            pos = floatList(n.attrs.pos)

            label = n.attrs.label
            try
                label = label.replace("\\N", k)
            catch e
                console.log label
            ctx.fillText(label, pos[0], pos[1])

            rx = parseFloat(n.attrs.width)*36
            ry = parseFloat(n.attrs.height)*36
            ctx.beginPath()
            ctx.ellipse(pos[0]-rx,pos[1]-ry,rx*2, ry*2)
            ctx.stroke()
    ctx.strokeStyle = 'blue'
    for k,e of graph.edges
        e = e[0]
        if e.attrs.pos
            points = e.attrs.pos.slice(2).split(' ').map(floatList)
            ctx.beginPath()
            ctx.moveTo(points[1][0], points[1][1])
            i = 2
            while i < points.length
                ctx.bezierCurveTo(points[i][0],points[i][1],points[i+1][0],points[i+1][1],points[i+2][0],points[i+2][1])
                i+=3
            ctx.stroke()
            ctx.beginPath()
            canvas_arrow(ctx, points[points.length-1][0],points[points.length-1][1],points[0][0],points[0][1])
            ctx.stroke()


window.onload = ->
    renderCurrent()
    renderToSvg(graph)
