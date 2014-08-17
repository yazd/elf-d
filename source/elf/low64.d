//          Copyright Yazan Dabain 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module elf.low64;
import elf.low;

package:

alias ELF64_Addr = ulong;
alias ELF64_Off = ulong;
alias ELF64_Half = ushort;
alias ELF64_Word = uint;
alias ELF64_SWord = int;
alias ELF64_XWord = ulong;
alias ELF64_SXword = long;

alias ELF64_Section = ushort;

align(1) struct ELFHeader64L {
align(1):
	ELFIdent ident;
	ELF64_Half type;
	ELF64_Half machine;
	ELF64_Word version_;
	ELF64_Addr entry;
	ELF64_Off phoff;
	ELF64_Off shoff;
	ELF64_Word flags;
	ELF64_Half ehsize;
	ELF64_Half phentsize;
	ELF64_Half phnum;
	ELF64_Half shentsize;
	ELF64_Half shnum;
	ELF64_Half shstrndx;
}

align(1) struct ELFSection64L {
align(1):
	ELF64_Word name;
	ELF64_Word type;
	ELF64_XWord flags;
	ELF64_Addr address;
	ELF64_Off offset;
	ELF64_XWord size;
	ELF64_Word link;
	ELF64_Word info;
	ELF64_XWord addralign;
	ELF64_XWord entsize;
}

align(1) struct ELFSymbol64L {
align(1):
	ELF64_Word name;
	ubyte info;
	ubyte other;
	ELF64_Half shndx;
	ELF64_Addr value;
	ELF64_XWord size;
}
