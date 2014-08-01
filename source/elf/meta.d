//          Copyright Yazan Dabain 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module elf.meta;

struct ReadFrom {
	string name;
}

string generateClassMixin(Interface, string ClassName, Source, int Bits)() {
	import std.string;
	string output = "";

	{
		output ~= "final class %s : %s {\n".format(ClassName, Interface.stringof);

		output ~= "  %s data;\n".format(Source.stringof);
		output ~= "  this(%s data) {\n".format(Source.stringof);
		output ~= "    this.data = data;\n";
		output ~= "  }\n";

		output ~= "  @property bool is32bit() { return %s; }\n".format(Bits == 32);
		output ~= "  @property bool is64bit() { return %s; }\n".format(Bits == 64);
		output ~= "  @property size_t datasize() { return %s.sizeof; }\n".format(Source.stringof);

		{
			foreach (MemberName; __traits(allMembers, Interface)) {
				static if (is(typeof(__traits(getMember, Interface, MemberName)))) {
					foreach (Attribute; __traits(getAttributes, __traits(getMember, Interface, MemberName))) {
						static if (is(typeof(Attribute) == ReadFrom)) {
							enum SourceMemberName = Attribute.name;
							alias MemberType = typeof(__traits(getMember, Interface, MemberName));
							alias SourceType = typeof(__traits(getMember, Source, SourceMemberName));

							static assert(SourceType.sizeof <= MemberType.sizeof, "%s shouldn\'t be downcast to %s".format(SourceMemberName, MemberType.stringof));

							output ~= "  @property override %s %s() {\n".format(MemberType.stringof, MemberName);
							output ~= "    return cast(%s) data.%s;\n".format(MemberType.stringof, SourceMemberName);
							output ~= "  }\n";
						}
					}
				}
			}
		}

		output ~= "}\n";
	}

	return output;
}

interface PortableHeader {
	@property bool is32bit();
	@property bool is64bit();
	@property size_t datasize();
}
