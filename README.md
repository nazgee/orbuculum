# orbuculum
Hooks to the build process and creates a compilation database file.

Internally uses https://github.com/rizsotto/Bear to create `compile_commands.json` that can be parsed by *CLion* IDE.

# sample usage
To create a super-project from 3 *AOSP* projects:
```
$ orbuculum.sh --out ~/myproj/compile_commands.json surfaceflinger hwcomposer.ranchu libgui
```
This will create a `~/myproj/compile_commands.json` database file that can be imported into an IDE.

If *orbuculum* is re-run for *ANOTHERM_MODULE*, the compilation database file will be extended with new data:
```
$ cat ~/myproj/compile_commands.json | wc -l
1626
$ orbuculum.sh --out ~/myproj/compile_commands.json ANOTHER MODULE

...

$ cat ~/myproj/compile_commands.json | wc -l
1844
```

After updating compilation database file, it should be reloaded in the IDE.

# troubleshooting
## Compilation database was not generated for my MODULE
If projects were already build, `make MODULE` invoked by *orbuculum* will probably not do anything -- compiler not be invoked.
To force *MODULE* rebuild `--clean` option can be added to *orbuculum* invocation:
```
orbuculum.sh --clean --out ~/myproj/compile_commands.json MODULE
```
`--clean` option forces  *orbuculum* to invoke `make clean-MODULE` before invoking `make MODULE`. In *AOSP*  project this will _usually_ result in full module rebuild (unfortunately, AOSP does not accept `-B` flag anymore...).

## Compilation database was not generated for my *MODULE* even with `--clean` flag
Some of the *AOSP* projects do not properly handle *clean*, for example would be `make clean-libgui` does not clean `.o` files. Instead of attempting to fix it, one can *touch* every source file before attempting a build, which will trick `make` into thinking that rebuild is needed. *orbuculum* has a tool called `pervert.sh` that *touches* every source code vfile in provided directory.

To rebuild a clean non-compliant module:
```
pervert.sh ./path/to/MODULE
orbuculum.sh --out ~/myproj/compile_commands.json MODULE
```
note: `--clean` is not needed when `pervert.sh` is used.


