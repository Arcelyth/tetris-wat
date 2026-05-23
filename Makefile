all: 
	wasm-as tetris.wat -o tetris.wasm -all
	python3 -m http.server 8000
