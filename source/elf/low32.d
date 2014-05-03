module elf.low32;
import elf.low;

package:

alias ELF32_Addr = uint;
alias ELF32_Off = uint;
alias ELF32_Half = ushort;
alias ELF32_Word = uint;
alias ELF32_SWord = int;

align(1) struct ELFHeader32L {
align(1):
  ELFIdent ident;
  ELF32_Half type;
  ELF32_Half machine;
  ELF32_Word version_;
  ELF32_Addr entry;
  ELF32_Off phoff;
  ELF32_Off shoff;
  ELF32_Word flags;
  ELF32_Half ehsize;
  ELF32_Half phentsize;
  ELF32_Half phnum;
  ELF32_Half shentsize;
  ELF32_Half shnum;
  ELF32_Half shstrndx;
}

align(1) struct ELFSection32L {
align(1):
  ELF32_Word name;
  ELF32_Word type;
  ELF32_Word flags;
  ELF32_Addr address;
  ELF32_Off offset;
  ELF32_Word size;
  ELF32_Word link;
  ELF32_Word info;
  ELF32_Word addralign;
  ELF32_Word entsize;
}

align(1) struct ELFSymbol32L {
align(1):
  ELF32_Word name;
  ELF32_Addr value;
  ELF32_Word size;
  ubyte info;
  ubyte other;
  ELF32_Half shndx;
}
