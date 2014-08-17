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
alias ELF_Section = ELF64_Section;

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
		return cast(FileClass) data.class_;
	}

	DataEncoding dataEncoding() {
		return cast(DataEncoding) data.data;
	}

	OSABI osABI() {
		return cast(OSABI) data.osabi;
	}

	ubyte abiVersion() {
		return data.abiversion;
	}
}

enum FileClass : ubyte {
	class32 = 1, class64 = 2,
}

enum DataEncoding : ubyte {
	littleEndian = 1, bigEndian = 2,
}

enum OSABI : ubyte {
	sysv = 0x00,
	hpux = 0x01,
	netBSD = 0x02,
	linux = 0x03,
	solaris = 0x06,
	aix = 0x07,
	irix = 0x08,
	freeBSD = 0x09,
	openBSD = 0x0C,
	standalone = 0xFF,
}

enum ObjectFileType : ELF_Half {
	none = 0x0000,
	relocatable = 0x0001,
	executable = 0x0002,
	shared_ = 0x0003,
	core = 0x0004,
	lowOS = 0xFE00,
	highOS = 0xFEFF,
	lowProccessor = 0xFF00,
	highProcessor = 0xFFFF,
}

enum SectionType : ELF_Word {
	null_ = 0x0000_0000,
	programBits = 0x0000_0001,
	symbolTable = 0x0000_0002,
	stringTable = 0x0000_0003,
	relocation = 0x0000_0004,
	symbolHashTable = 0x0000_0005,
	dynamicLinkingTable =	0x0000_0006,
	note = 0x0000_0007,
	noBits = 0x0000_0008,
	rel = 0x0000_0009,
	shlib = 0x0000_000A,
	dynamicLoaderSymbolTable = 0x0000_000B,
	lowOS = 0x6000_0000,
	highOS = 0x6FFF_FFFF,
	lowProcessor = 0x7000_0000,
	highProcessor = 0x7FFF_FFFF,
}

// TODO: Review this
enum SectionFlag : ELF64_XWord {
	write = 0x0000_0001,
	alloc = 0x0000_0002,
	executable = 0x0000_0004,
	maskOS = 0x0F00_0000,
	maskProcessor = 0xF000_0000,
}

enum TargetISA : ELF_Word {
	sparc = 0x02,
	x86 = 0x03,
	mips = 0x08,
	powerpc = 0x14,
	arm = 0x28,
	superh = 0x2A,
	ia64 = 0x32,
	x86_64 = 0x3E,
	aarch64 = 0xB7,
}
