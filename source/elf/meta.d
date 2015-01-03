//          Copyright Yazan Dabain 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module elf.meta;

package:

struct ReadFrom {
	string name;
}

string generateVirtualReads(Interface, string dataSource)() {
	import std.string;
	string output = "";

	foreach (MemberName; __traits(allMembers, Interface)) {
		static if (is(typeof(__traits(getMember, Interface, MemberName)))) {
			foreach (Attribute; __traits(getAttributes, __traits(getMember, Interface, MemberName))) {
				static if (is(typeof(Attribute) == ReadFrom)) {
					enum SourceMemberName = Attribute.name;
					alias MemberType = typeof(__traits(getMember, Interface, MemberName));

					output ~= "  @property override %s %s() {\n".format(MemberType.stringof, MemberName);
					output ~= "    return cast(%s) %s.%s;\n".format(MemberType.stringof, dataSource, SourceMemberName);
					output ~= "  }\n";
				}
			}
		}
	}

	return output;
}
