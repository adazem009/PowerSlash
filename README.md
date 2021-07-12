# PowerSlash compiler (C version)
New PowerSlash compiler written in C.


## Compiling and using
```
gcc pwc.c -o pwc
./pwc filename
```


### Options
`-o` - output file:

```
./pwc -o output filename
```


`--string` - convert to one-line string after compilation:

```
./pwc filename --string
```

Useful for BIOS builds.
