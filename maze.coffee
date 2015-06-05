randrange = (min, max) ->
  Math.floor(Math.random() * (max - min) + min)

choice = (seq) -> seq[randrange(0, seq.length)]

# http://stackoverflow.com/a/11143926/792749
arrayEqual = (a, b) ->
  a.length is b.length and a.every (elem, i) -> elem is b[i]

ear = (x) ->
  console.log(x)
  x

class Maze

  constructor: (@dimensions) ->
    @passages = {}
    @portals = {}
    @finishes = {}
    @start = (0 for _ in @dimensions)

  neighbors: (cell) ->
    result = []
    for dimension, i in @dimensions
      for distance in [-1, 1] when cell[i] + distance in [0...dimension]
        result.push(cell[...i].concat([cell[i] + distance]).concat(
            cell[i + 1...]))
    result

  passageExists: (passage) ->
    passage of @passages

  isFinish: (cell) ->
    cell of @finishes

class RandomMaze extends Maze

  constructor: (dimensions) ->
    super(dimensions)
    # Generate maze using growing tree algorithm:
    @growingTree()
    # Choose maximally distant cells for start and finish to make it
    # interesting. # FIXME use double-Dijkstra instead of this simple
    # algorithm - it also works for mazes with cycles
    maxpathInfo = @maxpath((0 for _ in @dimensions), [])
    @start = maxpathInfo.cell1
    @finish = maxpathInfo.cell2
    @finishes[@finish] = true

  # Growing Tree Algorithm
  # http://weblog.jamisbuck.org/2011/1/27/maze-generation-growing-tree-algorithm
  growingTree: ->
    startingCell = (randrange(0, d) for d in @dimensions)
    activeCells = [startingCell]
    visitedCells = {}
    visitedCells[startingCell] = true
    until activeCells.length == 0
      cell = choice(activeCells)
      unvisitedNeighbors =
        (n for n in @neighbors(cell) when not (n of visitedCells))
      # TODO Only using *unvisited* neighbors rules out cycles - but you would
      # occasionally expect cycles in a "natural" maze. We could make picking a
      # visited neighbor merely improbable instead of impossible. But we first
      # need a more general longest-simple-path-finding algorithm (double
      # Dijkstra).
      if unvisitedNeighbors.length > 0
        neighbor = choice(unvisitedNeighbors)
        passage = [cell, neighbor]
        finish = neighbor
        passage.sort()
        @passages[passage] = true
        visitedCells[neighbor] = true
        activeCells.push(neighbor)
      else
        activeCells = activeCells.filter (c) -> c isnt cell
    return

  # Implementation of the http://cs.stackexchange.com/a/11264 algorithm
  # for finding the longest simple path in a tree in a single pass. This
  # implementation returns not only the height and diameter (length of the
  # longest simple path) of a subtree but also the two nodes at the ends of
  # the longest path. The first argument is the root of the subtree to
  # examine. Because our tree is undirected, the parent of that node (or an
  # empty array, if none) needs to be passed as the second argument to
  # identify the subtree.
  # Returns an object with four fields: cell1 is the deepest node in the
  # subtree, cell2 is the node with the maximal distance from cell1 in the
  # subtree, diameter is that distance, height is the height of the subtree
  # (i.e. the distance of cell from cell1).
  maxpath: (cell, parent) ->
    children = (neighbor for neighbor in @neighbors(cell) \
        when not arrayEqual(neighbor, parent) \
        and @passageExists([neighbor, cell].sort()))
    if children.length == 0
      {cell1: cell, cell2: cell, height: 0, diameter: 0}
    else
      # Calculate heights, diameters and most distant nodes of children:
      results = (@maxpath(child, cell) for child in children)
      # Add dummy result in case there's only one. The -1 is to compensate for
      # the fact that we can only add one edge in the first case, not two.
      results.push({cell1: cell, height: -1, diameter: 0})
      # Find the two highest subtrees:
      results.sort((a, b) -> b.height - a.height)
      highest = results[0]
      secondHighest = results[1]
      # Find the subtree with the greatest diameter:
      results.sort((a, b) -> b.diameter - a.diameter)
      amplest = results[0]
      if highest.height + secondHighest.height + 2 > amplest.diameter
        # The longest simple path passes through cell
        {cell1: highest.cell1, cell2: secondHighest.cell1, \
            height: highest.height + 1, \
            diameter: highest.height + secondHighest.height + 2}
      else
        # The longest simple path does not pass through cell
        {cell1: amplest.cell1, cell2: amplest.cell2, \
            height: highest.height + 1, \
            diameter: amplest.diameter}

class LevelChooser extends Maze
  @waitingPosition = {
      3: [1, 3, 0]
      4: [1, 3, 0]
      5: [0, 2, 0]
      6: [3, 2, 0]
      7: [1, 0, 0]
      8: [1, 2, 0]
  }

  constructor: (@nextLevel=3) ->
    super([4, 4, 1])
    @start = LevelChooser.waitingPosition[@nextLevel] || LevelChooser.waitingPosition[8]
    # row 0
    @passages[[[0, 0, 0], [1, 0, 0]]] = true
    @passages[[[1, 0, 0], [2, 0, 0]]] = true
    @passages[[[2, 0, 0], [3, 0, 0]]] = true
    # row 0 to row 1
    @passages[[[1, 0, 0], [1, 1, 0]]] = true
    # row 1
    @passages[[[1, 1, 0], [2, 1, 0]]] = true
    @passages[[[2, 1, 0], [3, 1, 0]]] = true
    # row 1 to row 2
    @passages[[[0, 1, 0], [0, 2, 0]]] = true
    @passages[[[2, 1, 0], [2, 2, 0]]] = true
    @passages[[[3, 1, 0], [3, 2, 0]]] = true
    # row 2
    @passages[[[0, 2, 0], [1, 2, 0]]] = true
    @passages[[[1, 2, 0], [2, 2, 0]]] = true
    # row 2 to row 3
    @passages[[[1, 2, 0], [1, 3, 0]]] = true
    @passages[[[3, 2, 0], [3, 3, 0]]] = true
    # row 3
    @passages[[[0, 3, 0], [1, 3, 0]]] = true
    @passages[[[1, 3, 0], [2, 3, 0]]] = true
    # portals to levels
    @portals[[0, 3, 0]] = 3
    @portals[[2, 3, 0]] = 4
    @portals[[0, 1, 0]] = 5
    @portals[[3, 3, 0]] = 6
    @portals[[0, 0, 0]] = 7
    @portals[[3, 0, 0]] = 8

class MazeUI3D
  @msg =  {}
  @msg['arrows'] = 'Use the arrow keys to move around the maze.'
  @msg['updown'] = 'Press R to move a floor up, F to move a floor down.'
  @msg['win'] = 'Yay! You mastered the maze!'

  constructor: (@maze, @frame, @messagebox, @viewport) ->
    # dynamic attributes
    [@x, @y, @z] = @maze.start
    @busy = false
    @queue = []
    @moves = 0
    @status = 'playing'

    # floor positions
    width = @maze.dimensions[0] * 71 + 1
    height = @maze.dimensions[1] * 71 + 1
    @here = {
        width: width
        height: height
        top: Math.round(width / 2)
        left: Math.round(height / 2)
        opacity: 1
    }
    @above = {
        width: 2 * @here.width
        height: 2 * @here.height
        top: 0
        left: 0
        opacity: 0
    }
    width = Math.round(2 / 3 * @here.width)
    height = Math.round(2 / 3 * @here.height)
    @below = {
        width: width
        height: height
        top: Math.round((@above.height - height) / 2)
        left: Math.round((@above.width - width) / 2)
        opacity: 0
    }

    # set viewport
    #@viewport.attr('content', "width=#{@here.width + 142}");

    # style frame
    @frame.css({
        height: @here.height + 71
        width: @here.width + 71
        position: 'relative'
    })

    # make container
    @container = $('<div class=container></div>').css({
        position: 'absolute'
        top: (@here.height - @above.height + 71) / 2
        left: (@here.width - @above.width + 71) / 2
    })
    @frame.append(@container)

    # make invisible grid on which the pawn moves
    grid = $('<div class=grid></div>').css({
        width: @here.width
        height: @here.height
        position: 'relative',
        top: @here.top
        left: @here.left
        zIndex: 10
    })
    @container.append(grid)

    # make pawn
    @pawn = $('<canvas class=pawn width=70 height=70></canvas>').css({
       position: 'relative'
       top: @y * 71
       left: @x * 71
    })
    pawnContext = @pawn[0].getContext('2d')
    imageObj = new Image()
    imageObj.onload = ->
      pawnContext.drawImage(imageObj, 0, 0)
    imageObj.src = 'dot.png'
    grid.append(@pawn)

    # draw floors
    @floors = []
    for z in [0...@maze.dimensions[2]]
      floor = $('<canvas class=floor></canvas>').attr({
          width: @here.width
          height: @here.height
      })
      context = floor[0].getContext('2d')
      context.font = "50px 'Slabo 27px'"
      context.fillStyle = 'grey'
      for y in [-1...@maze.dimensions[1]]
        for x in [-1...@maze.dimensions[0]]
          context.strokeStyle = 'black'
          context.lineWidth = 1
          if !@maze.passageExists([[x, y, z], [x + 1, y, z]])
            # paint right wall
            context.beginPath()
            context.moveTo(71.5 + 71 * x, 0.5 + 71 * y)
            context.lineTo(71.5 + 71 * x, 71.5 + 71 * y)
            context.lineWidth = 1
            context.stroke()
          if !@maze.passageExists([[x, y, z], [x, y + 1, z]])
            # paint bottom wall
            context.beginPath()
            context.moveTo(0.5 + 71 * x, 71.5 + 71 * y)
            context.lineTo(71.5 + 71 * x, 71.5 + 71 * y)
            context.lineWidth = 1
            context.stroke()
          context.strokeStyle = 'grey'
          if @maze.isFinish([x, y, z])
            # paint finish mark 
            context.beginPath()
            context.arc(71 * x + 35, 71 * y + 35, 13.5, 0, 2 * Math.PI, false)
            context.stroke()
            context.beginPath()
            context.moveTo(71 * x + 35, 71 * y + 15)
            context.lineTo(71 * x + 35, 71 * y + 55)
            context.stroke()
            context.moveTo(71 * x + 15, 71 * y + 35)
            context.lineTo(71 * x + 55, 71 * y + 35)
            context.stroke()
          if [x, y, z] of @maze.portals
            context.fillText(@maze.portals[[x, y, z]], 71 * x + 20, 71 * y + 55)
          context.lineWidth = 2
          if @maze.passageExists([[x, y, z], [x, y, z + 1]])
            # paint up arrow
            context.beginPath()
            context.moveTo(x * 71 + 27, y * 71 + 18)
            context.lineTo(x * 71 + 35, y * 71 + 13)
            context.lineTo(x * 71 + 43, y * 71 + 18)
            context.lineWidth = 2
            context.stroke()
          if @maze.passageExists([[x, y, z - 1], [x, y, z]])
            # paint down arrow
            context.beginPath()
            context.moveTo(x * 71 + 27, y * 71 + 53)
            context.lineTo(x * 71 + 35, y * 71 + 58)
            context.lineTo(x * 71 + 43, y * 71 + 53)
            context.lineWidth = 2
            context.stroke()
      @floors[z] = floor
      @container.append(floor)
      floor.css({
          position: 'absolute'
      })
      if z < @z
        floor.css(@below)
      else if z == @z
        floor.css(@here)
      else
        floor.css(@above)

    # attach key event handlers
    $(document).keyup(@handleEvent)

    # message box
    @updateStatus()

    # show the whole thing
    @container.fadeIn(600)
    @messagebox.fadeIn(600)

  handleEvent: (event) =>
    if event.which == 27 or event.which == 8
      @playAgain(@maze.dimensions[0])
    else if @status == 'playing'
      if event.which == 82 # R key
        @goUp()
      else if event.which == 70 # F key
        @goDown()
      else if event.which == 37 # Left key
        @goLeft()
      else if event.which == 38 # Up key
        @goForward()
      else if event.which == 39 # Right key
        @goRight()
      else if event.which == 40 # Down key
        @goBackward()
    else if @status == 'frozen'
       if event.which == 80 # P key
         @playAgain(@maze.dimensions[0] + 1)
       else if event.which == 84 # T key
         @tweet()

  freeze: ->
    @queue = []
    @status = 'frozen'

  destroy: (complete=$.noop) ->
    @freeze()
    $(document).off('keyup')
    @container.fadeOut(600)
    @messagebox.fadeOut(600)
    @container.promise().done(=>
        @messagebox.promise().done(=>
            @container.remove()
            complete()
        )
    )

  whenIdle: (callback) =>
    @queue.push(callback)
    @continue()

  continue: =>
    if @busy
      setTimeout(@continue, 10)
    else
      @queue.shift()()

  startMove: =>
    @busy = true

  moveDone: =>
    @updateStatus()
    @busy = false

  goUp: ->
    @whenIdle =>
      if @maze.passageExists([[@x, @y, @z], [@x, @y, @z + 1]])
        @startMove()
        @floors[@z].animate(@below, 600)
        @z += 1
        @moves++
        @floors[@z].animate(@here, 600, @moveDone)

  goDown: ->
    @whenIdle =>
      if @maze.passageExists([[@x, @y, @z - 1], [@x, @y, @z]])
        @startMove()
        @floors[@z].animate(@above, 600)
        @z -= 1
        @moves++
        @floors[@z].animate(@here, 600, @moveDone)

  goBackward: ->
    @whenIdle =>
      if @maze.passageExists([[@x, @y, @z], [@x, @y + 1, @z]])
        @startMove()
        @y += 1
        @moves++
        @movePawn(@moveDone)

  goForward: ->
    @whenIdle =>
      if @maze.passageExists([[@x, @y - 1, @z], [@x, @y, @z]])
        @startMove()
        @y -= 1
        @moves++
        @movePawn(@moveDone)

  goRight: ->
    @whenIdle =>
      if @maze.passageExists([[@x, @y, @z], [@x + 1, @y, @z]])
        @startMove()
        @x += 1
        @moves++
        @movePawn(@moveDone)

  goLeft: ->
    @whenIdle =>
      if @maze.passageExists([[@x - 1, @y, @z], [@x, @y, @z]])
        @startMove()
        @x -= 1
        @moves++
        @movePawn(@moveDone)

  movePawn: (callback) ->
    @pawn.animate({
          top: @y * 71
          left: @x * 71
    }, 200, callback)

  currentMessage: ->
    if @maze.isFinish([@x, @y, @z])
      MazeUI3D.msg['win']
    else if @maze.passageExists([[@x, @y, @z], [@x, @y, @z + 1]]) or @maze.passageExists([[@x, @y, @z - 1], [@x, @y, @z]])
      MazeUI3D.msg['updown']
    else
      MazeUI3D.msg['arrows']

  updateStatus: ->
    @messagebox.html('<p>' + @currentMessage() + '</p>')
    if @maze.isFinish([@x, @y, @z])
      @freeze()
      @messagebox.append($('<p></p>').append(@makeActionLink('<span class=shortcut>t</span>weet', => @tweet())).append('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;').append(@makeActionLink('<span class=shortcut>p</span>lay again', => @playAgain(@maze.dimensions[0] + 1))))
    if [@x, @y, @z] of @maze.portals
      level = @maze.portals[[@x, @y, @z]]
      @destroy( =>
          new MazeUI3D(new RandomMaze([level, level, level]), @frame,
              @messagebox,
              @viewport)
      )

  makeActionLink: (text, callback) =>
    $('<a></a>')
        .attr({
            class: 'actionLink'
            href: '#'
        }).append(text).click(callback)

  playAgain: (nextLevel=3) =>
    @destroy( =>
        new LevelChooserUI(new LevelChooser(nextLevel), @frame, @messagebox,
                @viewport)
    )

  tweet: =>
    window.open('https://twitter.com/share?text=' + encodeURIComponent(
        @makeTweetText()))

  makeTweetText: ->
    article = if @maze.dimensions[0] == 8 then 'an' else 'a' # Grammar, baby!
    "I solved #{article} #{@maze.dimensions[0]}x#{@maze.dimensions[1]}x#{@maze.dimensions[2]} #maze in #{@moves} moves!"

class LevelChooserUI extends MazeUI3D

  currentMessage: ->
    'Welcome to the maze!<br>Use the arrow keys to move and choose a level.'

root = exports ? this
root.RandomMaze = RandomMaze
root.MazeUI3D = MazeUI3D
root.LevelChooser = LevelChooser
root.LevelChooserUI = LevelChooserUI
