//          Copyright Yazan Dabain 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module elf;

public import elf.sections;

import elf.low, elf.low32, elf.low64, elf.meta;

import std.mmfile;
import std.exception;
import std.conv : to;
import std.typecons : Nullable;

static if (__VERSION__ >= 2079)
	alias elfEnforce = enforce!ELFException;
else
	alias elfEnforce = enforceEx!ELFException;

abstract class ELF {
	MmFile m_file;

	private this(MmFile file) {
		this.m_file = file;
	}

	static ELF fromFile(string filepath) {
		MmFile file = new MmFile(filepath);
		return ELF.fromFile(file);
	}

	static ELF fromFile(MmFile file) {
		elfEnforce(file.length > 16);
		elfEnforce(file[0 .. 4] == ['\x7f', 'E', 'L', 'F']);
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
				elfEnforce(!empty, "out of bounds exception");
				return this[m_currentIndex];
			}

			void popFront() {
				elfEnforce(!empty, "out of bounds exception");
				this.m_currentIndex++;
			}

			@property typeof(this) save() {
				return this;
			}

			ELFSection opIndex(size_t index) {
				elfEnforce(index < m_elf.header.numberOfSectionHeaderEntries, "out of bounds exception");
				auto sectionStart = m_elf.header.sectionHeaderOffset + index * m_elf.header.sizeOfSectionHeaderEntry;
				auto section = m_elf.m_file[sectionStart .. sectionStart + m_elf.header.sizeOfSectionHeaderEntry];
				return this.m_elf.buildSection(cast(ubyte[]) section);
			}
		}
		return Sections(this);
	}

	// linear lookup
	Nullable!ELFSection getSection(string name) {
		foreach (section; this.sections) {
			if (section.name == name) return Nullable!ELFSection(section);
		}
		return Nullable!ELFSection();
	}

	StringTable getSectionNamesStringTable() {
		ELFSection section = this.sections[this.header.sectionHeaderStringTableIndex];
		return StringTable(section);
	}

	Nullable!StringTable getSymbolsStringTable() {
		Nullable!ELFSection section = this.getSection(".strtab");
		if (section.isNull) return Nullable!StringTable();
		else return Nullable!StringTable(StringTable(section.get()));
	}
}

final class ELF64 : ELF {
	ELFHeader64 m_header;

	this(MmFile file) {
		super(file);

		ELFHeader64L headerData = *(cast(ELFHeader64L*) file[0 .. ELFHeader64L.sizeof].ptr);
		this.m_header = new ELFHeader64(headerData);
	}

	override @property ELFHeader header() {
		return this.m_header;
	}

	override ELFSection64 buildSection(ubyte[] sectionData) {
		elfEnforce(sectionData.length == ELFSection64L.sizeof);
		ELFSection64L sectionRep = *(cast(ELFSection64L*) sectionData.ptr);
		ELFSection64 section = new ELFSection64(this, sectionRep);
		section.m_elf = this;
		return section;
	}
}

final class ELF32 : ELF {
	ELFHeader32 m_header;

	this(MmFile file) {
		super(file);

		ELFHeader32L headerData = *(cast(ELFHeader32L*) file[0 .. ELFHeader32L.sizeof].ptr);
		this.m_header = new ELFHeader32(headerData);
	}

	override @property ELFHeader header() {
		return this.m_header;
	}

	override ELFSection32 buildSection(ubyte[] sectionData) {
		elfEnforce(sectionData.length == ELFSection32L.sizeof);
		ELFSection32L sectionRep = *(cast(ELFSection32L*) sectionData.ptr);
		ELFSection32 section = new ELFSection32(this, sectionRep);
		return section;
	}
}

abstract class ELFHeader {
	@property:
	@ReadFrom("ident") Identifier identifier();
	@ReadFrom("type") ObjectFileType objectFileType();
	@ReadFrom("machine") TargetISA machineISA();
	@ReadFrom("version_") ELF_Word version_();
	@ReadFrom("entry") ELF_Addr entryPoint();
	@ReadFrom("phoff") ELF_Off programHeaderOffset();
	@ReadFrom("shoff") ELF_Off sectionHeaderOffset();
	@ReadFrom("phentsize") ELF_Half sizeOfProgramHeaderEntry();
	@ReadFrom("phnum") ELF_Half numberOfProgramHeaderEntries();
	@ReadFrom("shentsize") ELF_Half sizeOfSectionHeaderEntry();
	@ReadFrom("shnum") ELF_Half numberOfSectionHeaderEntries();
	@ReadFrom("shstrndx") ELF_Half sectionHeaderStringTableIndex();
}

final class ELFHeader32 : ELFHeader {
	private ELFHeader32L m_data;
	mixin(generateVirtualReads!(ELFHeader, "m_data"));

	this(ELFHeader32L data) {
		this.m_data = data;
	}
}

final class ELFHeader64 : ELFHeader {
	private ELFHeader64L m_data;
	mixin(generateVirtualReads!(ELFHeader, "m_data"));

	this(ELFHeader64L data) {
		this.m_data = data;
	}
}

abstract class ELFSection {
	package ELF m_elf;

	@property:
	@ReadFrom("name") ELF_Word nameIndex();
	@ReadFrom("type") SectionType type();
	@ReadFrom("flags") SectionFlag flags();
	@ReadFrom("address") ELF_Addr address();
	@ReadFrom("offset") ELF_Off offset();
	@ReadFrom("size") ELF_XWord size();
	@ReadFrom("link") ELF_Word link();
	@ReadFrom("info") ELF_Word info();
	@ReadFrom("addralign") ELF_XWord addrAlign();
	@ReadFrom("entsize") ELF_XWord entrySize();

	ubyte bits();

	auto name() {
		return m_elf.getSectionNamesStringTable().getStringAt(this.nameIndex());
	}

	auto contents() {
		return cast(ubyte[]) m_elf.m_file[offset() .. offset() + size()];
	}
}

final class ELFSection32 : ELFSection {
	private ELFSection32L m_data;
	mixin(generateVirtualReads!(ELFSection, "m_data"));

	this(ELF32 elf, ELFSection32L data) {
		this.m_elf = elf;
		this.m_data = data;
	}

	override @property ubyte bits() {
		return 32;
	}
}

final class ELFSection64 : ELFSection {
	private ELFSection64L m_data;
	mixin(generateVirtualReads!(ELFSection, "m_data"));

	this(ELF64 elf, ELFSection64L data) {
		this.m_elf = elf;
		this.m_data = data;
	}

	override @property ubyte bits() {
		return 64;
	}
}

class ELFException : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}
