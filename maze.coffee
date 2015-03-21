randrange = (min, max) ->
  Math.floor(Math.random() * (max - min) + min)

choice = (seq) -> seq[randrange(0, seq.length)]

ear = (x) ->
  console.log(x)
  x

class Maze
  constructor: (@dimensions) ->
    @growing_tree()

  neighbors: (cell) ->
    result = []
    for dimension, i in @dimensions
      for distance in [-1, 1] when cell[i] + distance in [0...dimension]
        result.push(cell[...i].concat([cell[i] + distance]).concat(
            cell[i + 1...]))
    result

  growing_tree: ->
    @passages = {}
    @starting_cell = (randrange(0, d) for d in @dimensions)
    active_cells = [@starting_cell]
    visited_cells = {} # using joined tuples for keys
    until active_cells.length == 0
      cell = choice(active_cells)
      unvisited_neighbors =
        (n for n in @neighbors(cell) when not (n of visited_cells))
      if unvisited_neighbors.length > 0
        neighbor = choice(unvisited_neighbors)
        passage = [cell, neighbor]
        @target = neighbor
        passage.sort()
        @passages[passage] = true
        visited_cells[neighbor] = true
        active_cells.push(neighbor)
      else
        active_cells = active_cells.filter (c) -> c isnt cell
    return

  passage_exists: (passage) ->
    passage of @passages

class MazeUI3D
  constructor: (@maze, @div) ->
    # initialize attributes
    [@x, @y, @z] = @maze.starting_cell
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
    @floors = []

    # style board
    @div.css({
        width: @above.width,
        height: @above.height,
        position: 'relative'
    })

    # make invisible grid on which the pawn moves
    @grid = $('<div></div>').css({
        width: @here.width
        height: @here.height
        position: 'relative',
        top: @here.top
        left: @here.left
        zIndex: 10
    })
    @div.append(@grid)

    # make pawn
    @pawn = $('<canvas></canvas>').css({
       position: 'relative'
       top: @y * 71
       left: @x * 71
    })
    pawnContext = @pawn[0].getContext('2d')
    pawnX = 71 / 2
    pawnY = 71 / 2
    pawnRadius = 11
    pawnContext.beginPath()
    pawnContext.arc(pawnX, pawnY, pawnRadius, 0, 2 * Math.PI, false)
    pawnContext.fillStyle = '#800000'
    pawnContext.fill()
    @grid.append(@pawn)

    # draw floors
    for z in [0...@maze.dimensions[2]]
      floor = $('<canvas></canvas>').attr({
          width: @here.width
          height: @here.height
      })
      context = floor[0].getContext('2d')
      for y in [-1...@maze.dimensions[1]]
        for x in [-1...@maze.dimensions[0]]
          if !@maze.passage_exists([[x, y, z], [x + 1, y, z]])
            context.beginPath()
            context.moveTo(71.5 + 71 * x, 0.5 + 71 * y)
            context.lineTo(71.5 + 71 * x, 71.5 + 71 * y)
            context.lineWidth = 1
            context.strokeStyle = 'black'
            context.stroke()
          if !@maze.passage_exists([[x, y, z], [x, y + 1, z]])
            context.beginPath()
            context.moveTo(0.5 + 71 * x, 71.5 + 71 * y)
            context.lineTo(71.5 + 71 * x, 71.5 + 71 * y)
            context.lineWidth = 1
            context.strokeStyle = 'black'
            context.stroke()
          if @maze.passage_exists([[x, y, z], [x, y, z + 1]])
            # paint up arrow
            context.beginPath()
            context.moveTo(x * 71 + 27, y * 71 + 18)
            context.lineTo(x * 71 + 35, y * 71 + 13)
            context.lineTo(x * 71 + 43, y * 71 + 18)
            context.lineWidth = 3
            context.strokeStyle = 'grey'
            context.stroke()
          if @maze.passage_exists([[x, y, z - 1], [x, y, z]])
            # paint down arrow
            context.beginPath()
            context.moveTo(x * 71 + 27, y * 71 + 53)
            context.lineTo(x * 71 + 35, y * 71 + 58)
            context.lineTo(x * 71 + 43, y * 71 + 53)
            context.lineWidth = 3
            context.strokeStyle = 'grey'
            context.stroke()
      @floors[z] = floor
      @div.append(floor)
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
    $(document).keyup((event) =>
      if event.which == 82 # R key
        @go_up()
      else if event.which == 70 # F key
        @go_down()
      else if event.which == 37 # Left key
        @go_left()
      else if event.which == 38 # Up key
        @go_forward()
      else if event.which == 39 # Right key
        @go_right()
      else if event.which == 40 # Down key
        @go_backward()
    )

  # TODO synchronize all movements!

  go_up: ->
    if @maze.passage_exists([[@x, @y, @z], [@x, @y, @z + 1]])
      @floors[@z].animate(@below, 1500)
      @z += 1
      @floors[@z].animate(@here, 1500)

  go_down: ->
    if @maze.passage_exists([[@x, @y, @z - 1], [@x, @y, @z]])
      @floors[@z].animate(@above, 1500)
      @z -= 1
      @floors[@z].animate(@here, 1500)

  go_backward: ->
    if @maze.passage_exists([[@x, @y, @z], [@x, @y + 1, @z]])
      @y += 1
      @move_pawn()

  go_forward: ->
    if @maze.passage_exists([[@x, @y - 1, @z], [@x, @y, @z]])
      @y -= 1
      @move_pawn()

  go_right: ->
    if @maze.passage_exists([[@x, @y, @z], [@x + 1, @y, @z]])
      @x += 1
      @move_pawn()

  go_left: ->
    if @maze.passage_exists([[@x - 1, @y, @z], [@x, @y, @z]])
      @x -= 1
      @move_pawn()

  move_pawn: ->
    @pawn.animate({
        top: @y * 71
        left: @x * 71
    })

root = exports ? this
root.Maze = Maze
root.MazeUI3D = MazeUI3D
