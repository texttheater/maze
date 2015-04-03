maze.js : maze.coffee
	coffee --compile $<

deploy : maze.js
	rsync -r * texttheater2@texttheater.net:~/httpdocs/maze
