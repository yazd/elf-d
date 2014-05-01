module elf.sections;

import elf.elf;
import elf.low;

import std.exception;
import std.conv : to;

class Section {
  private ELF parent;
  private ELFSection section;
  package this(ELF parent, ubyte[] section) {
    this.parent = parent;
    this.section = *(cast(ELFSection*) section.ptr);
  }

  enum Type : ELF64_Word {
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

  enum Flag : ELF64_XWord {
    write = 0x1,
    alloc = 0x2,
    executable = 0x4,
    maskOS = 0x0F00_0000,
    maskProcessor = 0xF000_0000,
  }

  @property {
    string name() {
      return parent.sections.getSectionNamesStringTable().getAt(section.name);
    }

    Type type() {
      return cast(Type) section.type;
    }

    auto address() {
      return section.address;
    }

    auto flags() {
      return cast(Flag) section.flags;
    }

    auto offset() {
      return section.offset;
    }

    auto size() {
      return section.size;
    }

    auto entrySize() {
      return section.entsize;
    }

    auto contents() {
      return cast(ubyte[]) parent.file[offset .. offset + size];
    }
  }
}

struct StringTable {
  private Section section;
  package this(Section section) {
    this.section = section;
  }

  string opIndex(size_t index) {
    import std.algorithm: splitter;
    import std.range: drop;
    return cast(string) section.contents.splitter('\0').drop(index).front;
  }

  string getAt(size_t offset) {
    import std.algorithm: until, map;
    return section.contents[offset .. $].until('\0').map!(to!char).to!string;
  }

  string[] strings() {
    import std.algorithm: splitter, map;
    import std.array: array;
    return section.contents.splitter('\0').map!(a => cast(string) a).array();
  }
}
