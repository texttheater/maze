maze.js : maze.coffee
	coffee --compile $<

deploy : maze.js
	@[ "${SRV}" ] || ( echo ">> SRV is not set"; exit 1 )
	rsync dot.png font.css forkme_right_gray_6d6d6d.png image.png index.html jquery-3.7.1.min.js maze.css maze.js Slabo27px-Regular.ttf ${SRV}/maze/
