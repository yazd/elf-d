//          Copyright Yazan Dabain 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module elf.sections.symboltable;

import std.exception;
import std.conv : to;
import elf, elf.low, elf.low32, elf.low64, elf.meta;

static if (__VERSION__ >= 2079)
	alias elfEnforce = enforce!ELFException;
else
	alias elfEnforce = enforceEx!ELFException;


struct SymbolTable {
	private SymbolTableImpl m_impl;

	this(ELFSection section) {
		if (section.bits == 32) {
			m_impl = new SymbolTable32Impl(section);
		} else {
			m_impl = new SymbolTable64Impl(section);
		}
	}

	ELFSymbol getSymbolAt(size_t index) {
		return m_impl.getSymbolAt(index);
	}

	auto symbols() {
		static struct Symbols {
			private SymbolTableImpl m_impl;
			private size_t m_currentIndex = 0;

			@property bool empty() { return m_currentIndex >= m_impl.length; }

			@property ELFSymbol front() {
				elfEnforce(!empty, "out of bounds exception");
				return m_impl.getSymbolAt(m_currentIndex);
			}

			void popFront() {
				elfEnforce(!empty, "out of bounds exception");
				this.m_currentIndex++;
			}

			@property typeof(this) save() {
				return this;
			}

			this(SymbolTableImpl impl) {
				this.m_impl = impl;
			}
		}

		return Symbols(this.m_impl);
	}
}

private interface SymbolTableImpl {
	ELFSymbol getSymbolAt(size_t index);
	@property ulong length();
}

private class SymbolTable32Impl : SymbolTableImpl {
	private ELFSection32 m_section;

	this(ELFSection section) {
		elfEnforce(section.bits == 32);
		this(cast(ELFSection32) section);
	}

	this(ELFSection32 section) {
		this.m_section = section;
	}

	ELFSymbol getSymbolAt(size_t index) {
		elfEnforce(index * ELFSymbol32L.sizeof < m_section.size);
		ELFSymbol32L symbol;
		symbol = *cast(ELFSymbol32L*) m_section.contents[index * ELFSymbol32L.sizeof .. (index + 1) * ELFSymbol32L.sizeof].ptr;
		return new ELFSymbol32(m_section, symbol);
	}

	@property ulong length() {
		return m_section.size / ELFSymbol32L.sizeof;
	}
}

private class SymbolTable64Impl : SymbolTableImpl {
	private ELFSection64 m_section;

	this(ELFSection section) {
		elfEnforce(section.bits == 64);
		this(cast(ELFSection64) section);
	}

	this(ELFSection64 section) {
		this.m_section = section;
	}

	ELFSymbol getSymbolAt(size_t index) {
		elfEnforce(index * ELFSymbol64L.sizeof < m_section.size);
		ELFSymbol64L symbol;
		symbol = *cast(ELFSymbol64L*) m_section.contents[index * ELFSymbol64L.sizeof .. (index + 1) * ELFSymbol64L.sizeof].ptr;
		return new ELFSymbol64(m_section, symbol);
	}

	@property ulong length() {
		return m_section.size / ELFSymbol64L.sizeof;
	}
}

abstract class ELFSymbol {
	private ELFSection m_section;

	@property:
	@ReadFrom("name") ELF_Word nameIndex();
	@ReadFrom("info") ubyte info();
	@ReadFrom("other") ubyte other();
	@ReadFrom("shndx") ELF_Section sectionIndex();
	@ReadFrom("value") ELF_Addr value();
	@ReadFrom("size") ELF_XWord size();

	string name() {
		StringTable strtab = StringTable(m_section.m_elf.sections[m_section.link()]);
		return strtab.getStringAt(nameIndex);
	}

	SymbolBinding binding() {
		return cast(SymbolBinding) (this.info() >> 4);
	}

	SymbolType type() {
		return cast(SymbolType) (this.info() & 0xF);
	}
}

final class ELFSymbol32 : ELFSymbol {
	private ELFSymbol32L m_symbol;
	mixin(generateVirtualReads!(ELFSymbol, "m_symbol"));

	this(ELFSection32 section, ELFSymbol32L symbol) {
		this.m_section = section;
		this.m_symbol = symbol;
	}
}

final class ELFSymbol64 : ELFSymbol {
	private ELFSymbol64L m_symbol;
	mixin(generateVirtualReads!(ELFSymbol, "m_symbol"));

	this(ELFSection64 section, ELFSymbol64L symbol) {
		this.m_section = section;
		this.m_symbol = symbol;
	}
}

enum SymbolBinding {
	local = 0,
	global = 1,
	weak = 2,
	loproc = 13,
	hiproc = 15,
}

enum SymbolType {
	notype = 0,
	object = 1,
	func = 2,
	section = 3,
	file = 4,
	loproc = 13,
	hiproc = 15,
}
