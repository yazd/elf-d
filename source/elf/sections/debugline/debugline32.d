//          Copyright Yazan Dabain 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module elf.sections.debugline.debugline32;

align(1) struct LineProgramHeader32L {
align(1):
	uint unitLength;
	ushort dwarfVersion;
	uint headerLength;
	ubyte minimumInstructionLength;
	bool defaultIsStatement;
	byte lineBase;
	ubyte lineRange;
	ubyte opcodeBase;
}
