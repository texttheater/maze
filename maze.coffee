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
    @width = @maze.dimensions[0] * 71 + 1
    @height = @maze.dimensions[1] * 71 + 1
    @left = Math.round(@width / 2)
    @top = Math.round(@height / 2)
    @above_width = 2 * @width
    @above_height = 2 * @height
    @above_left = Math.round((@width - @above_width) / 2)
    @above_top = Math.round((@height - @above_height) / 2)
    @below_width = Math.round(2 / 3 * @width)
    @below_height = Math.round(2 / 3 * @height)
    @below_left = Math.round((@width - @below_width) / 2)
    @below_top = Math.round((@height - @below_height) / 2)
    @floors = []

    # style board
    @div.css({
        width: @above_width,
        height: @above_height,
        position: 'relative'
    })
    # TODO somehow need to set the CSS width/height/top/left attributes
    # of .floorBelow, .floorAbove and .floorHere - but jQuery is not a great
    # help in manipulating CCS classes. >:-(

    # draw floors
    for z in [0...@maze.dimensions[2]]
      floor = $('<canvas></canvas>').attr({
          width: @width,
          height: @height
      })
      context = floor[0].getContext('2d')
      context.lineWidth = 1
      context.strokeStyle = 'black'
      for y in [-1...@maze.dimensions[1]]
        for x in [-1...@maze.dimensions[0]]
          if !@maze.passage_exists([[x, y, z], [x + 1, y, z]])
            context.beginPath()
            context.moveTo(71.5 + 71 * x, 0.5 + 71 * y)
            context.lineTo(71.5 + 71 * x, 71.5 + 71 * y)
            context.stroke()
          if !@maze.passage_exists([[x, y, z], [x, y + 1, z]])
            context.beginPath()
            context.moveTo(0.5 + 71 * x, 71.5 + 71 * y)
            context.lineTo(71.5 + 71 * x, 71.5 + 71 * y)
            context.stroke()
          # TODO paint arrows
      @floors[z] = floor
      @div.append(floor)
      floor.addClass('floor')
      if z < @z
        floor.addClass('floorBelow')
      else if z == @z
        floor.addClass('floorHere')
      else
        floor.addClass('floorAbove')

    # attach key event handlers
    # TODO this should only work when  player is in legal position
    # TODO arrow keys
    $(document).keyup((event) =>
      if event.which == 82 # R key
        @go_up()
      else if event.which == 70 # F key
        @go_down()
    )

  go_up: ->
    # TODO wait until previous animation is finished
    if @z + 1 >= @maze.dimensions[2]
      return
    @floors[@z].switchClass('floorHere', 'floorBelow', {duration: 1500})
    @z += 1
    @floors[@z].switchClass('floorAbove', 'floorHere', {duration: 1500})

  go_down: ->
    # TODO wait until previous animation is finished
    if @z - 1 < 0
      return
    @floors[@z].switchClass('floorHere', 'floorAbove', {duration: 1500})
    @z -= 1
    @floors[@z].switchClass('floorBelow', 'floorHere', {duration: 1500})

root = exports ? this
root.Maze = Maze
root.MazeUI3D = MazeUI3D
