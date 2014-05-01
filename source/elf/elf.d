module elf.elf;

public import elf.sections;
import elf.low;

import std.mmfile;
import std.bitmanip;
import std.exception;
import std.conv : to;

static assert(is(size_t == ulong), "only 64bit is supported for now");

class ELF {
  package MmFile file;

  this(string filepath) {
    file = new MmFile(filepath);
    checkValidity();
  }

  private void checkValidity() {
    enforce(file.length > 4);
    enforce(file[0 .. 4] == ['\x7f', 'E', 'L', 'F']);
  }

  @property private ref ELFHeader64 header() {
    return *(cast(ELFHeader64*) file[0 .. ELFHeader64.sizeof].ptr);
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

  enum ObjectFileType : ELF64_Half {
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

  @property {
    FileClass fileClass() {
      return header.ident.class_.to!FileClass;
    }

    DataEncoding dataEncoding() {
      return header.ident.data.to!DataEncoding;
    }

    OSABI osABI() {
      return header.ident.osabi.to!OSABI;
    }

    auto abiVersion() {
      return header.ident.abiversion;
    }

    ObjectFileType objectFileType() {
      return cast(ObjectFileType) header.type;
    }

    auto entryPoint() {
      return header.entry;
    }

    auto programHeaderOffset() {
      return header.phoff;
    }

    auto sectionHeaderOffset() {
      return header.shoff;
    }

    auto sizeOfProgramHeaderEntry() {
      return header.phentsize;
    }

    auto numberOfProgramHeaderEntries() {
      return header.phnum;
    }

    auto sizeOfSectionHeaderEntry() {
      return header.shentsize;
    }

    auto numberOfSectionHeaderEntries() {
      return header.shnum;
    }

    auto sections() {
      struct Sections {
        ELF elf;
        this(ELF elf) { this.elf = elf; }
        Section opIndex(size_t index) {
          enforce(index < elf.numberOfSectionHeaderEntries, "out of bounds access");
          auto section = elf.file[elf.header.shoff + index * elf.header.shentsize .. elf.header.shoff + index * elf.header.shentsize + elf.header.shentsize];
          return new Section(elf, cast(ubyte[]) section);
        }

        StringTable getSectionNamesStringTable() {
          return StringTable(this[elf.header.shstrndx]);
        }

        StringTable getSymbolStringTable() {
          foreach (i; 0 .. elf.numberOfSectionHeaderEntries) {
            Section s = this[i];
            if (s.name == ".strtab") return StringTable(s);
          }
          throw new Exception("symbol string table not found");
        }
      }

      return Sections(this);
    }
  }
}

