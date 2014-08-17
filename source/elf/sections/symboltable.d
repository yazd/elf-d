//          Copyright Yazan Dabain 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module elf.sections.symboltable;

import std.exception;
import std.conv : to;
import elf, elf.low, elf.low32, elf.low64, elf.meta;

alias enforce = enforceEx!ELFException;

struct SymbolTable {
	private SymbolTableImpl m_impl;

	this(ELFSection section) {
		if (section.is32bit()) {
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
				enforce(!empty, "out of bounds exception");
				return m_impl.getSymbolAt(m_currentIndex);
			}

			void popFront() {
				enforce(!empty, "out of bounds exception");
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

mixin(generateClassMixin!(ELFSymbol, "ELFSymbol32", ELFSymbol32L, 32));
mixin(generateClassMixin!(ELFSymbol, "ELFSymbol64", ELFSymbol64L, 64));

private interface SymbolTableImpl {
	ELFSymbol getSymbolAt(size_t index);
	@property ulong length();
}

private class SymbolTable32Impl : SymbolTableImpl {
	private ELFSection m_section;

	this(ELFSection section) {
		enforce(section.is32bit());
		this.m_section = section;
	}

	ELFSymbol getSymbolAt(size_t index) {
		enforce(index * ELFSymbol32L.sizeof < m_section.size);
		ELFSymbol32L symbol;
		symbol = *cast(ELFSymbol32L*) m_section.contents[index * ELFSymbol32L.sizeof .. (index + 1) * ELFSymbol32L.sizeof].ptr;
		return new ELFSymbol32(symbol);
	}

	@property ulong length() {
		return m_section.size / ELFSymbol32L.sizeof;
	}
}

private class SymbolTable64Impl : SymbolTableImpl {
	private ELFSection m_section;

	this(ELFSection section) {
		enforce(section.is64bit());
		this.m_section = section;
	}

	ELFSymbol getSymbolAt(size_t index) {
		enforce(index * ELFSymbol64L.sizeof < m_section.size);
		ELFSymbol64L symbol;
		symbol = *cast(ELFSymbol64L*) m_section.contents[index * ELFSymbol64L.sizeof .. (index + 1) * ELFSymbol64L.sizeof].ptr;
		return new ELFSymbol64(symbol);
	}

	@property ulong length() {
		return m_section.size / ELFSymbol64L.sizeof;
	}
}

abstract class ELFSymbol : PortableHeader {
	@property:
	@ReadFrom("name") ELF_Word nameIndex();
	@ReadFrom("info") ubyte info();
	@ReadFrom("other") ubyte other();
	@ReadFrom("shndx") ELF_Section sectionIndex();
	@ReadFrom("value") ELF_Addr value();
	@ReadFrom("size") ELF_XWord size();

	string name(StringTable strTable) {
		return strTable.getStringAt(nameIndex);
	}

	SymbolBinding binding() {
		return cast(SymbolBinding) (this.info() >> 4);
	}
}

enum SymbolBinding {
	local = 0,
	global = 1,
	weak = 2,
	loproc = 13,
	hiproc = 15,
}
