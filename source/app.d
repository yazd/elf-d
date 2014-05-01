import std.stdio;
import elf.elf;
import std.string;

void main() {
  import std.file: thisExePath;
  auto file = thisExePath();

  ELF elf = new ELF(file);
  writeln(elf.fileClass);
  writeln(elf.dataEncoding);
  writeln(elf.abiVersion);
  writeln(elf.osABI);
  writeln(elf.objectFileType);
  writefln("0x%x", elf.entryPoint);
  writeln(elf.programHeaderOffset);
  writeln(elf.sectionHeaderOffset);
  writeln(elf.sizeOfProgramHeaderEntry);
  writeln(elf.numberOfProgramHeaderEntries);
  writeln(elf.sizeOfSectionHeaderEntry);
  writeln(elf.numberOfSectionHeaderEntries);

  writeln();

  writefln("%(%s\n%)", elf.sections.getSymbolStringTable().strings);

  foreach (i; 0 .. elf.numberOfSectionHeaderEntries) {
    Section section = elf.sections[i];
    writeln("Section ", i, " (", section.name, ")");
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