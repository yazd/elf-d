import std.stdio;
import std.string;
import std.algorithm, std.range;
import elf;

void main() {
	import std.file: thisExePath;
	auto file = thisExePath();

	ELF elf = ELF.fromFile(file);

	writeln("File: ", file);

	writeln();
	writeln("ELF file properties:");

	// ELF file general properties
	writeln("  fileClass: ", elf.header.identifier.fileClass);
	writeln("  dataEncoding: ", elf.header.identifier.dataEncoding);
	writeln("  abiVersion: ", elf.header.identifier.abiVersion);
	writeln("  osABI: ", elf.header.identifier.osABI);
	writeln("  objectFileType: ", elf.header.objectFileType);
	writeln("  machineISA: ", elf.header.machineISA);
	writeln("  version_: ", elf.header.version_);
	writefln("  entryPoint: 0x%x", elf.header.entryPoint);
	writeln("  programHeaderOffset: ", elf.header.programHeaderOffset);
	writeln("  sectionHeaderOffset: ", elf.header.sectionHeaderOffset);
	writeln("  sizeOfProgramHeaderEntry: ", elf.header.sizeOfProgramHeaderEntry);
	writeln("  numberOfProgramHeaderEntries: ", elf.header.numberOfProgramHeaderEntries);
	writeln("  sizeOfSectionHeaderEntry: ", elf.header.sizeOfSectionHeaderEntry);
	writeln("  numberOfSectionHeaderEntries: ", elf.header.numberOfSectionHeaderEntries);

	writeln();
	writeln("Sections:");

	// ELF sections
	foreach (section; elf.sections) {
		writeln("  Section (", section.name, ")");
		writefln("    type: %s", section.type);
		writefln("    address: 0x%x", section.address);
		writefln("    offset: 0x%x", section.offset);
		writefln("    flags: 0x%08b", section.flags);
		writefln("    size: %s bytes", section.size);
		writefln("    entry size: %s bytes", section.entrySize);
		writeln();
	}

	printDebugAbbrev(elf);
	//printDebugLine(elf);
	//printSymbolTables(elf);
}

void printDebugAbbrev(ELF elf) {
	writeln();
	writeln("'.debug_abbrev' section contents:");

	// ELF .debug_abbrev information
	ELFSection dlSection = elf.getSection(".debug_abbrev").get;

	auto da = DebugAbbrev(dlSection);
	foreach (tag; da.tags) {
		writefln("Tag (0x%x):", tag.code);
		writefln("  name: %s", tag.name);
		writefln("  has children: %s", tag.hasChildren);
		writefln("  attributes:");
		foreach (attr; tag.attributes) {
			writefln("    %s\t%s", attr.name, attr.form);
		}
		writeln();
	}
}

void printDebugLine(ELF elf) {
	writeln();
	writeln("'.debug_line' section contents:");

	// ELF .debug_line information
	ELFSection dlSection = elf.getSection(".debug_line").get;

	auto dl = DebugLine(dlSection);
	foreach (program; dl.programs) {
		writefln("  Files:\n%-(    %s\n%)\n", program.allFiles());
		writefln("%-(  %s\n%)", program.addressInfo.map!(a => "0x%x => %s@%s".format(a.address, program.fileFromIndex(a.fileIndex), a.line)));
	}
}

void printSymbolTables(ELF elf) {
	writeln();
	writeln("Symbol table sections contents:");

	foreach (section; only(".symtab", ".dynsym")) {
		ELFSection s = elf.getSection(section).get;
		writeln("  Symbol table ", section, " contains: ", SymbolTable(s).symbols().walkLength());

		writefln("%-(    %s\n%)", SymbolTable(s).symbols().map!(s => "%s\t%s\t%s".format(s.binding, s.type, s.name)));
		writeln();
	}
}
