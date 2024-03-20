CC=emcc
CONFIGURE=emconfigure
EMMAKE=emmake
CFLAGS=-std=c++20 -Oz -sERROR_ON_UNDEFINED_SYMBOLS=0 -sFILESYSTEM=0 -sASSERTIONS=0 -sEXPORT_KEEPALIVE=1 --no-entry
INCLUDE_FLAGS=

all: build

build: cetz.cpp
	$(CC) $(CFLAGS) cetz.cpp -o cetz.wasm $(INCLUDE_FLAGS)
	wasi-stub cetz.wasm -o cetz.wasm

clean:
	rm *.wasm || true
