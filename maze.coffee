randrange = (min, max) ->
  Math.floor(Math.random() * (max - min) + min)

choice = (seq) -> seq[randrange(0, seq.length)]

# http://stackoverflow.com/a/11143926/792749
array_equal = (a, b) ->
  a.length is b.length and a.every (elem, i) -> elem is b[i]

ear = (x) ->
  console.log(x)
  x

class Maze
  constructor: (@dimensions) ->
    # Generate maze using growing tree algorithm:
    @growing_tree()
    # Choose maximally distant cells for start and finish to make it
    # interesting:
    maxpath_info = @maxpath((0 for _ in @dimensions), [])
    @start = maxpath_info.cell1
    @finish = maxpath_info.cell2
    @finishes = {}
    @finishes[@finish] = true

  neighbors: (cell) ->
    result = []
    for dimension, i in @dimensions
      for distance in [-1, 1] when cell[i] + distance in [0...dimension]
        result.push(cell[...i].concat([cell[i] + distance]).concat(
            cell[i + 1...]))
    result

  # Growing Tree Algorithm
  # http://weblog.jamisbuck.org/2011/1/27/maze-generation-growing-tree-algorithm
  growing_tree: ->
    @passages = {}
    starting_cell = (randrange(0, d) for d in @dimensions)
    active_cells = [starting_cell]
    visited_cells = {}
    visited_cells[starting_cell] = true
    until active_cells.length == 0
      cell = choice(active_cells)
      unvisited_neighbors =
        (n for n in @neighbors(cell) when not (n of visited_cells))
      if unvisited_neighbors.length > 0
        neighbor = choice(unvisited_neighbors)
        passage = [cell, neighbor]
        target = neighbor
        passage.sort()
        @passages[passage] = true
        visited_cells[neighbor] = true
        active_cells.push(neighbor)
      else
        active_cells = active_cells.filter (c) -> c isnt cell
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
        when not array_equal(neighbor, parent) \
        and @passage_exists([neighbor, cell].sort()))
    if children.length == 0
      {cell1: cell, cell2: cell, height: 0, diameter: 0}
    else
      # Calculate heights, diameters and most distant nodes of children:
      results = (@maxpath(child, cell) for child in children)
      # Add dummy result in case there's only one:
      results.push({cell1: null, cell2: null, height: 0, diameter: 0})
      # Find the two highest subtrees:
      results.sort((a, b) -> b.height - a.height)
      highest = results[0]
      second_highest = results[1]
      # Find the subtree with the greatest diameter:
      results.sort((a, b) -> b.diameter - a.diameter)
      amplest = results[0]
      if highest.height + second_highest.height > amplest.diameter
        # The longest simple path passes through cell
        {cell1: highest.cell1, cell2: second_highest.cell1, \
            height: highest.height + 1, \
            diameter: highest.height + second_highest.height + 2}
      else
        # The longest simple path does not pass through cell
        {cell1: amplest.cell1, cell2: amplest.cell2, \
            height: highest.height + 1, \
            diameter: amplest.diameter}

  passage_exists: (passage) ->
    passage of @passages

  is_target: (cell) ->
    cell of @finishes

class MazeUI3D
  @msg =  {}
  @msg['arrows'] = 'Use the arrow keys to move around the maze.'
  @msg['updown'] = 'Press R to move a floor up, F to move a floor down.'
  @msg['win'] = 'Congratulations! You mastered the maze!'

  constructor: (@maze, frame, @messagebox) ->
    # dynamic attributes 
    [@x, @y, @z] = @maze.start

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

    # style frame
    frame.css({
        height: @here.height + 142
        width: @above.width
        position: 'relative'
    })

    # make container
    container = $('<div></div>').css({
        width: @above.width
        height: @above.height
        position: 'absolute'
        top: (@here.height - @above.height + 142) / 2
    })
    frame.append(container)

    # make invisible grid on which the pawn moves
    grid = $('<div></div>').css({
        width: @here.width
        height: @here.height
        position: 'relative',
        top: @here.top
        left: @here.left
        zIndex: 10
    })
    container.append(grid)

    # make pawn
    @pawn = $('<canvas></canvas>').css({
       position: 'relative'
       top: @y * 71
       left: @x * 71
    })
    pawnContext = @pawn[0].getContext('2d')
    imageObj = new Image()
    imageObj.onload = ->
      pawnContext.drawImage(imageObj, 0, 0)
    imageObj.src = 'img/dot.png'
    grid.append(@pawn)

    # draw floors
    @floors = []
    for z in [0...@maze.dimensions[2]]
      floor = $('<canvas></canvas>').attr({
          width: @here.width
          height: @here.height
      })
      context = floor[0].getContext('2d')
      for y in [-1...@maze.dimensions[1]]
        for x in [-1...@maze.dimensions[0]]
          if !@maze.passage_exists([[x, y, z], [x + 1, y, z]])
            # paint right wall
            context.beginPath()
            context.moveTo(71.5 + 71 * x, 0.5 + 71 * y)
            context.lineTo(71.5 + 71 * x, 71.5 + 71 * y)
            context.lineWidth = 1
            context.strokeStyle = 'black'
            context.stroke()
          if !@maze.passage_exists([[x, y, z], [x, y + 1, z]])
            # paint bottom wall
            context.beginPath()
            context.moveTo(0.5 + 71 * x, 71.5 + 71 * y)
            context.lineTo(71.5 + 71 * x, 71.5 + 71 * y)
            context.lineWidth = 1
            context.strokeStyle = 'black'
            context.stroke()
          if @maze.is_target([x, y, z])
            # paint target
            context.beginPath()
            context.arc(71 * x + 71 / 2, 71 * y + 71 / 2, 21, 0, 2 * Math.PI, false)
            context.lineWidth = 10
            context.strokeStyle = 'black'
            context.stroke()
            context.beginPath()
            context.arc(71 * x + 71 / 2, 71 * y + 71 / 2, 10, 0, 2 * Math.PI, false)
            context.fillStyle = 'black'
            context.fill()
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
      container.append(floor)
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
        @update_msg()
      else if event.which == 70 # F key
        @go_down()
        @update_msg()
      else if event.which == 37 # Left key
        @go_left()
        @update_msg()
      else if event.which == 38 # Up key
        @go_forward()
        @update_msg()
      else if event.which == 39 # Right key
        @go_right()
        @update_msg()
      else if event.which == 40 # Down key
        @go_backward()
        @update_msg()
    )

    # messagebox
    @messagebox.html('<p>' + MazeUI3D.msg['arrows'] + '</p>')

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

  update_msg: ->
    if @maze.is_target([@x, @y, @z])
      msg = MazeUI3D.msg['win']
    else if @maze.passage_exists([[@x, @y, @z], [@x, @y, @z + 1]]) or @maze.passage_exists([[@x, @y, @z - 1], [@x, @y, @z]])
      msg = MazeUI3D.msg['updown']
    else
      msg = MazeUI3D.msg['arrows']
    @messagebox.html('<p>' + msg + '</p>')

root = exports ? this
root.Maze = Maze
root.MazeUI3D = MazeUI3D
