//          Copyright Yazan Dabain 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module elf;

public import elf.sections;

import elf.low, elf.meta;

import std.mmfile;
import std.exception;
import std.conv : to;

alias enforce = enforceEx!ELFException;

abstract class ELF {
	package MmFile m_file;

	private this(MmFile file) {
		this.m_file = file;
	}

	static ELF fromFile(string filepath) {
		MmFile file = new MmFile(filepath);
		return ELF.fromFile(file);
	}

	static ELF fromFile(MmFile file) {
		enforce(file.length > 16);
		bool is32Bit = (file[4] == 1);
		bool is64Bit = (file[4] == 2);

		if (is32Bit) {
			return new ELF32(file);
		} else if (is64Bit) {
			return new ELF64(file);
		} else {
			throw new ELFException("invalid elf file class");
		}
	}

  private void checkValidity() {
    enforce(m_file.length > 16);
    enforce(m_file[0 .. 4] == ['\x7f', 'E', 'L', 'F']);
  }

  @property ELFHeader header();
  ELFSection buildSection(ubyte[] section);

	@property auto sections() {
    struct Sections {
      private size_t m_currentIndex = 0;
      ELF m_elf;

      this(ELF elf) { this.m_elf = elf; }

      @property bool empty() { return m_currentIndex >= m_elf.header.numberOfSectionHeaderEntries; }
      @property size_t length() { return m_elf.header.numberOfSectionHeaderEntries - m_currentIndex; }

      @property ELFSection front() {
      	return this[m_currentIndex];
      }

      void popFront() {
      	enforce(!empty, "out of bounds exception");
      	this.m_currentIndex++;
      }

      @property typeof(this) save() {
      	return this;
      }

      ELFSection opIndex(size_t index) {
        enforce(index < m_elf.header.numberOfSectionHeaderEntries, "out of bounds access");
        auto sectionStart = m_elf.header.sectionHeaderOffset + index * m_elf.header.sizeOfSectionHeaderEntry;
        auto section = m_elf.m_file[sectionStart .. sectionStart + m_elf.header.sizeOfSectionHeaderEntry];
        return this.m_elf.buildSection(cast(ubyte[]) section);
      }
    }
    return Sections(this);
  }

  StringTable getSectionNamesStringTable() {
  	ELFSection section = this.sections[this.header.sectionHeaderStringTableIndex];
  	return StringTable(section);
  }

  StringTable getSymbolsStringTable() {
    foreach (section; this.sections) {
      if (section.name == ".strtab") return StringTable(section);
    }
    assert(0, "symbol string table not found");
  }
}

final class ELF64 : ELF {
	import elf.low64;

	mixin(generateClassMixin!(ELFHeader, "ELFHeader64", ELFHeader64L));
	ELFHeader64 m_header;

	mixin(generateClassMixin!(ELFSection, "ELFSection64", ELFSection64L));

	this(MmFile file) {
		super(file);

		ELFHeader64L headerData = *(cast(ELFHeader64L*) file[0 .. ELFHeader64L.sizeof].ptr);
		this.m_header = new ELFHeader64(headerData);
	}

	override @property ELFHeader header() {
		return this.m_header;
	}

	override ELFSection64 buildSection(ubyte[] sectionData) {
		enforce(sectionData.length == ELFSection64L.sizeof);
		ELFSection64L sectionRep = *(cast(ELFSection64L*) sectionData.ptr);
		ELFSection64 section = new ELFSection64(sectionRep);
		section.m_elf = this;
		return section;
	} 
}

final class ELF32 : ELF {
	import elf.low32;

	mixin(generateClassMixin!(ELFHeader, "ELFHeader32", ELFHeader32L));
	ELFHeader32 m_header;

	mixin(generateClassMixin!(ELFSection, "ELFSection32", ELFSection32L));

	this(MmFile file) {
		super(file);

		ELFHeader32L headerData = *(cast(ELFHeader32L*) file[0 .. ELFHeader32L.sizeof].ptr);
		this.m_header = new ELFHeader32(headerData);
	}

	override @property ELFHeader header() {
		return this.m_header;
	}

	override ELFSection32 buildSection(ubyte[] sectionData) {
		enforce(sectionData.length == ELFSection32L.sizeof);
		ELFSection32L sectionRep = *(cast(ELFSection32L*) sectionData.ptr);
		ELFSection32 section = new ELFSection32(sectionRep);
		section.m_elf = this;
		return section;
	}
}

abstract class ELFHeader {
	@property:
  @ReadFrom("ident") Identifier identifier();
  @ReadFrom("type") ObjectFileType objectFileType();
  @ReadFrom("entry") ELF_Addr entryPoint();
  @ReadFrom("phoff") ELF_Off programHeaderOffset();
  @ReadFrom("shoff") ELF_Off sectionHeaderOffset();
  @ReadFrom("phentsize") ELF_Half sizeOfProgramHeaderEntry();
  @ReadFrom("phnum") ELF_Half numberOfProgramHeaderEntries();
  @ReadFrom("shentsize") ELF_Half sizeOfSectionHeaderEntry();
  @ReadFrom("shnum") ELF_Half numberOfSectionHeaderEntries();
  @ReadFrom("shstrndx") ELF_Half sectionHeaderStringTableIndex();
}

abstract class ELFSection {
	private ELF m_elf;

	@property:
	@ReadFrom("name") ELF_Word nameIndex();
	@ReadFrom("type") SectionType type();
	@ReadFrom("address") ELF_Addr address();
	@ReadFrom("flags") SectionFlag flags();
	@ReadFrom("offset") ELF_Off offset();
	@ReadFrom("size") ELF_XWord size();
	@ReadFrom("entsize") ELF_XWord entrySize();

	auto name() {
		return m_elf.getSectionNamesStringTable().getStringAt(this.nameIndex());
	}

	auto contents() {
	  return cast(ubyte[]) m_elf.m_file[offset() .. offset() + size()];
	}
}

class ELFException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}