//          Copyright Yazan Dabain 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module elf.sections.debugline.debugline64;

align(1) struct LineProgramHeader64L {
align(1):
	uint unitLength_;
	ulong unitLength;
	ushort dwarfVersion;
	ulong headerLength;
	ubyte minimumInstructionLength;
	bool defaultIsStatement;
	byte lineBase;
	ubyte lineRange;
	ubyte opcodeBase;
}
