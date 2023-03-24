# VDFtoJSON

A plugin which converts Valve Data Format (VDF) files to JSON format

### Installing

Drag the compiled .smx or download the whole scripting folder and compile yourself

### Requirements

https://github.com/ErikMinekus/sm-ripext/releases/latest

### Compiler

Pawn 1.11 - build 6934

## Usage
```c
#include <vdftojson>

//param1 origin    addons/sourcemod/
//param2 origin    addons/sourcemod/data/
//param3 encoding  VDFType_8,VDFType_16
VDFReturn c = VDFtoJSON("../../scripts/items/items_game.txt","test.json", VDFType_8);
```

## Built With

* [SourcePawn](https://www.sourcemod.net) - Interface to CS:GO

## Authors

* **Oscar Wos** - *Whole Project* - [AlliedModders](https://forums.alliedmods.net/member.php?u=261698) | [GitHub](https://github.com/OSCAR-WOS)

* **p0358** - *vdf-parser* - [GitHub](https://github.com/p0358)



## License

This project is licensed under the GPL V3 License - see the [LICENSE](LICENSE) file for details