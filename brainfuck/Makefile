objects = build/main.o build/brainfuck.o build/read_file.o
.PHONY: clean

brainfuck: $(objects)
	$(CC) -no-pie -g -o "$@" $^

build:
	mkdir build

build/%.o: %.s | build
	$(CC) -no-pie -c -g -o "$@" "$<"

clean:
	rm -rf brainfuck build
