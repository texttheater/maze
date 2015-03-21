maze.js : maze.coffee
	coffee --compile $<

deploy :
	rsync -r * texttheater2@texttheater.net:~/httpdocs/maze
