import std.stdio;
import std.string;
import elf;

void main() {
	import std.file: thisExePath;
	auto file = thisExePath();

	ELF elf = ELF.fromFile(file);
	writeln(elf.header.identifier.fileClass);
	writeln(elf.header.identifier.dataEncoding);
	writeln(elf.header.identifier.abiVersion);
	writeln(elf.header.identifier.osABI);
	writeln(elf.header.objectFileType);
	writefln("0x%x", elf.header.entryPoint);
	writeln(elf.header.programHeaderOffset);
	writeln(elf.header.sectionHeaderOffset);
	writeln(elf.header.sizeOfProgramHeaderEntry);
	writeln(elf.header.numberOfProgramHeaderEntries);
	writeln(elf.header.sizeOfSectionHeaderEntry);
	writeln(elf.header.numberOfSectionHeaderEntries);

	writeln();

	writefln("%-(%s\n%)", elf.getSymbolsStringTable().strings);

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

}

string printValue(T)(auto ref T source) if (is(T == struct)) {
	auto fields = __traits(allMembers, typeof(source));
	auto values = source.tupleof;

	auto output = "";
	foreach (index, value; values) {
		output ~= "%-15s %s\n".format(fields[index], printValue(value));
	}

	return output;
}

string printValue(T)(auto ref T source) if (!is(T == struct)) {
	return "%s".format(source);
}