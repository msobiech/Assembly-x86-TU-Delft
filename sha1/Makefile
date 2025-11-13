.PHONY: clean

sha1: sha1.s sha1_test64.so
	$(CC) -g -Wl,-rpath=. -o "$@" $^

clean:
	rm -f sha1
