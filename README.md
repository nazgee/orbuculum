# Orbuculum
*orbuculum* is a simple utility that hooks into the build process and creates a *compilation database file*. Compilation database contains information about compilation options (include paths, defines, flags) which is useful for *IDEs* to generete a source code index that is 'proper' - no more blindly grepping through the source code and wondering which `#ifdef` is correct.

Compilation database can be generated in 2 formats
- clang's `compile_commands.json` - can be imported to *CLion* IDE
- `CMakeLists.txt` - can be used by *Eclipse*, *QTCreator* and more

By default only `compile_commands.json` database file is generated. To generate it *orbuculum* uses [bear](https://github.com/rizsotto/Bear). When given `--json2cmake` option, *orbuculum* will use [json2cmake](https://github.com/AbigailBuccaneer/json2cmake) to additionally generate `CMakeLists.txt` file.

# Prerequisites
- [bear](https://github.com/rizsotto/Bear) - download, compile & install: `git clone https://github.com/rizsotto/Bear; cd Bear; cmake ./; make; sudo make install`
- [json2cmake](https://github.com/AbigailBuccaneer/json2cmake) install: `pip install --user json2cmake`

If `json2cmake` is not available after the steps above (should not usually happen), manually create an executable file with the following contents:
```bash
#!/bin/bash
python -m json2cmake.__init__
```

# Usage
There are 2 steps needed to work with properly *indexed* source code:
- generate *compilation database file*
- import database to an IDE

## Generating compilation database
To create a super-project database for 3 *AOSP* projects:
```
$ orbuculum.sh --out ~/myproj/compile_commands.json surfaceflinger hwcomposer.ranchu libgui
>>> BuildEAR'ing 'surfaceflinger'
>>> BuildEAR'ing 'hwcomposer.ranchu'
>>> BuildEAR'ing 'libgui'
>>> Completede BuildEAR'ing of:
- surfaceflinger
- hwcomposer.ranchu
- libgui
>>> Output: '~/myproj/compile_commands.json'
```
This creates a `~/myproj/compile_commands.json` database file that can be imported into an IDE. If `~/myproj/CMakeLists.txt` is desired, add `--json2cmake` option.

If *orbuculum* is re-run for *ANOTHER_MODULE*, the compilation database file will be **extended** with new data:
```
$ cat ~/myproj/compile_commands.json | wc -l
1626
$ orbuculum.sh --out ~/myproj/compile_commands.json ANOTHER_MODULE
...
$ cat ~/myproj/compile_commands.json | wc -l
1844
```
**note:** After updating compilation database file, it should be reloaded in the IDE

## Importing compilation database
### CLion
*CLion* version *2018.2* uses `compile_commands.json`. Details are described [here](https://blog.jetbrains.com/clion/2018/05/clion-2018-2-eap-open-project-from-compilation-database/), but in general:
- Select 'Open' point it to your 'compile_commands.json' (**note:** file name is important - other names will not work)
- Click 'Open as a project'
- Done!

Optionally, to 'unflatten' the files view (and be able to open the rest of project files, not only these that are present in database)
- Go to `Tools` --> `Compilation Database` --> `Change Project Roots` and point to project's root (e.g. *AOSP* root directory)
- Wait
### Eclipse
TBD
*Eclipse* can use `CMakeLists.txt`.
### QTCreator
TBD
*Eclipse* can use `CMakeLists.txt`.

# Troubleshooting
## Database not generated for MODULE
If project was already build, `make MODULE` invoked by *orbuculum* will not do anything -- specifically, compiler will not be invoked.
To force *MODULE* rebuild `--clean` option can be added to *orbuculum* invocation:
```
orbuculum.sh --clean --out ~/myproj/compile_commands.json MODULE
```
`--clean` option forces  *orbuculum* to invoke `make clean-MODULE` before invoking `make MODULE`. In *AOSP*  project this will _usually_ result in full module rebuild (unfortunately, *AOSP* does not accept passing `-B` option to `make` anymore).

## Database not generated for MODULE even with `--clean` option
Some of the *AOSP* projects do not properly handle *clean*, for example `make clean-libgui` does not clean `.o` files. Instead of attempting to fix it, one can *touch* every source file before attempting a build, which will force full rebuild next time `make MODULE` is invoked. *orbuculum* has a tool called `pervert.sh` that *touches* every source code file in given directory.

To rebuild a clean non-compliant module:
```
pervert.sh ./path/to/MODULE
orbuculum.sh --out ~/myproj/compile_commands.json MODULE
```
**note:** `--clean` is not needed when `pervert.sh` is used


