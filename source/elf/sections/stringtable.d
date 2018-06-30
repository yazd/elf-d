//          Copyright Yazan Dabain 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module elf.sections.stringtable;

import std.exception;
import std.conv : to;
import elf;

static if (__VERSION__ >= 2079)
	alias elfEnforce = enforce!ELFException;
else
	alias elfEnforce = enforceEx!ELFException;

struct StringTable {
	private ELFSection m_section;

	this(ELFSection section) {
		this.m_section = section;
	}

	string getStringAt(size_t index) {
		import std.algorithm: countUntil;

		elfEnforce(index < m_section.size);
		ptrdiff_t len = m_section.contents[index .. $].countUntil('\0');
		elfEnforce(len >= 0);

		return cast(string) m_section.contents[index .. index + len];
	}

	auto strings() {
		static struct Strings {
			private ELFSection m_section;
			private size_t m_currentIndex = 0;

			@property bool empty() { return m_currentIndex >= m_section.size; }

			@property string front() {
				elfEnforce(!empty, "out of bounds exception");
				ptrdiff_t len = frontLength();
				elfEnforce(len >= 0, "invalid data");
				return cast(string) m_section.contents[m_currentIndex .. m_currentIndex + len];
			}

			private auto frontLength() {
				import std.algorithm: countUntil;

				ptrdiff_t len = m_section.contents[m_currentIndex .. $].countUntil('\0');
				return len;
			}

			void popFront() {
				elfEnforce(!empty, "out of bounds exception");
				this.m_currentIndex += frontLength() + 1;
			}

			@property typeof(this) save() {
				return this;
			}

			this(ELFSection section) {
				this.m_section = section;
			}
		}

		return Strings(this.m_section);
	}
}
