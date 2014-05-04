//          Copyright Yazan Dabain 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module elf.low;

import elf.low32, elf.low64;
import elf.meta;

import std.conv : to;

alias ELF_Half = ELF64_Half;
alias ELF_Word = ELF64_Word;
alias ELF_SWord = ELF64_SWord;
alias ELF_XWord = ELF64_XWord;
alias ELF_Addr = ELF64_Addr;
alias ELF_Off = ELF64_Off;

align(1) struct ELFIdent {
align(1):
  char mag0;
  char mag1;
  char mag2;
  char mag3;
  ubyte class_;
  ubyte data;
  ubyte version_;
  ubyte osabi;
  ubyte abiversion;
  ubyte[6] pad;
  ubyte nident;
}

static assert(ELFIdent.sizeof == 16);

struct Identifier {
	ELFIdent data;

	FileClass fileClass() {
	  return data.class_.to!FileClass;
	}

	DataEncoding dataEncoding() {
	  return data.data.to!DataEncoding;
	}

	OSABI osABI() {
	  return data.osabi.to!OSABI;
	}

	ubyte abiVersion() {
	  return data.abiversion;
	}
}

enum FileClass {
  class32 = 1, class64 = 2,
}

enum DataEncoding {
  littleEndian = 1, bigEndian = 2,
}

enum OSABI {
  sysv = 0, hpux = 1, standalone = 255,
}

enum ObjectFileType : ELF_Half {
  none = 0,
  relocatable = 1,
  executable = 2,
  shared_ = 3,
  core = 4,
  lowOS = 0xFE00,
  highOS = 0xFEFF,
  lowProccessor = 0xFF00,
  highProcessor = 0xFFFF,
}

enum SectionType : ELF_Word {
  null_ = 0,
  programBits = 1,
  symbolTable = 2,
  stringTable = 3,
  rela = 4,
  symbolHashTable = 5,
  dynamicLinkingTable = 6,
  note = 7,
  noBits = 8,
  rel = 9,
  shlib = 10,
  dynamicLoaderSymbolTable = 11,
  lowOS = 0x6000_0000,
  highOS = 0x6FFF_FFFF,
  lowProcessor = 0x7000_0000,
  highProcessor = 0x7FFF_FFFF,
}

// TODO: Review this
enum SectionFlag : ELF64_XWord {
  write = 0x1,
  alloc = 0x2,
  executable = 0x4,
  maskOS = 0x0F00_0000,
  maskProcessor = 0xF000_0000,
}
