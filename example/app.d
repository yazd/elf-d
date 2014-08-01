import std.stdio;
import std.string;
import std.algorithm;
import elf;

void main() {
	import std.file: thisExePath;
	auto file = thisExePath();

	ELF elf = ELF.fromFile(file);

	// ELF file general properties
	writeln(elf.header.identifier.fileClass);
	writeln(elf.header.identifier.dataEncoding);
	writeln(elf.header.identifier.abiVersion);
	writeln(elf.header.identifier.osABI);
	writeln(elf.header.objectFileType);
	writeln(elf.header.machineISA);
	writeln(elf.header.version_);
	writefln("0x%x", elf.header.entryPoint);
	writeln(elf.header.programHeaderOffset);
	writeln(elf.header.sectionHeaderOffset);
	writeln(elf.header.sizeOfProgramHeaderEntry);
	writeln(elf.header.numberOfProgramHeaderEntries);
	writeln(elf.header.sizeOfSectionHeaderEntry);
	writeln(elf.header.numberOfSectionHeaderEntries);

	writeln();

	// ELF sections
	foreach (section; elf.sections) {
		writeln("Section (", section.name, ")");
		writefln("  type: %s", section.type);
		writefln("  address: 0x%x", section.address);
		writefln("  offset: 0x%x", section.offset);
		writefln("  flags: 0x%08b", section.flags);
		writefln("  size: %s bytes", section.size);
		writefln("  entry size: %s bytes", section.entrySize);
		writeln();
	}

	// ELF symbols string table
	writefln("%-(%s\n%)", elf.getSymbolsStringTable().strings);

	// ELF .debug_line information
	ELFSection dlSection = elf.sections.filter!(s => s.name == ".debug_line").front;

	import elf.sections.debugline;
	auto dl = DebugLine(dlSection);
	foreach (program; dl.programs) {
		writefln("%-(%s\n%)", program.addressInfo.map!(a => "0x%x => %s@%s".format(a.address, program.fileFromIndex(a.fileIndex), a.line)));
	}
}
