maze.js : maze.coffee
	coffee --compile $<

deploy : maze.js
	rsync -rdv --exclude \*.xcf * texttheater2@texttheater.net:~/httpdocs/maze
