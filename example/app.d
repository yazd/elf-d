import std.stdio;
import std.string;
import std.algorithm;
import elf;

void main() {
	import std.file: thisExePath;
	auto file = thisExePath();

	ELF elf = ELF.fromFile(file);

	writeln("File: ", file);

	// ELF file general properties
	writeln("fileClass: ", elf.header.identifier.fileClass);
	writeln("dataEncoding: ", elf.header.identifier.dataEncoding);
	writeln("abiVersion: ", elf.header.identifier.abiVersion);
	writeln("osABI: ", elf.header.identifier.osABI);
	writeln("objectFileType: ", elf.header.objectFileType);
	writeln("machineISA: ", elf.header.machineISA);
	writeln("version_: ", elf.header.version_);
	writefln("entryPoint: 0x%x", elf.header.entryPoint);
	writeln("programHeaderOffset: ", elf.header.programHeaderOffset);
	writeln("sectionHeaderOffset: ", elf.header.sectionHeaderOffset);
	writeln("sizeOfProgramHeaderEntry: ", elf.header.sizeOfProgramHeaderEntry);
	writeln("numberOfProgramHeaderEntries: ", elf.header.numberOfProgramHeaderEntries);
	writeln("sizeOfSectionHeaderEntry: ", elf.header.sizeOfSectionHeaderEntry);
	writeln("numberOfSectionHeaderEntries: ", elf.header.numberOfSectionHeaderEntries);

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
