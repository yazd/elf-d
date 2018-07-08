//          Copyright Yazan Dabain 2014.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module elf.sections.debugabbrev;

// this implementation follows the DWARF v3 documentation

import std.exception;
import std.range;
import std.conv : to;
import elf, elf.meta;

static if (__VERSION__ >= 2079)
	alias elfEnforce = enforce!ELFException;
else
	alias elfEnforce = enforceEx!ELFException;

alias ULEB128 = ulong;
alias LEB128 = long;

struct Tag {
	ULEB128 code;
	TagEncoding name;
	bool hasChildren;
	Attribute[] attributes;
}

struct Attribute {
	AttributeName name;
	AttributeForm form;
}

struct DebugAbbrev {
	private Tag[ULEB128] m_tags; // key is tag code

	this(ELFSection section) {
		ubyte[] contents = section.contents();

		while (true) {
			// read tag
			Tag tag;
			tag.code = contents.readULEB128();
			if (tag.code == 0) break; // read all tags
			tag.name = cast(TagEncoding) contents.readULEB128();
			tag.hasChildren = contents.read!bool();

			while (true) {
				// read attributes
				Attribute attr;
				attr.name = cast(AttributeName) contents.readULEB128();
				attr.form = cast(AttributeForm) contents.readULEB128();

				if (attr.name == 0 && attr.form == 0) break;
				tag.attributes ~= attr;
			}

			m_tags[tag.code] = tag;
		}
	}

	@property const(Tag[ULEB128]) tags() const { return m_tags; }
}

private T read(T)(ref ubyte[] buffer) {
	T result = *(cast(T*) buffer[0 .. T.sizeof].ptr);
	buffer.popFrontExactly(T.sizeof);
	return result;
}

private ulong readULEB128(ref ubyte[] buffer) {
	import std.array;
	ulong val = 0;
	ubyte b;
	uint shift = 0;

	while (true) {
		b = buffer.read!ubyte();

		val |= (b & 0x7f) << shift;
		if ((b & 0x80) == 0) break;
		shift += 7;
	}

	return val;
}

unittest {
	ubyte[] data = [0xe5, 0x8e, 0x26, 0xDE, 0xAD, 0xBE, 0xEF];
	assert(readULEB128(data) == 624_485);
	assert(data[] == [0xDE, 0xAD, 0xBE, 0xEF]);
}

private long readSLEB128(ref ubyte[] buffer) {
	import std.array;
	long val = 0;
	uint shift = 0;
	ubyte b;
	int size = 8 << 3;

	while (true) {
		b = buffer.read!ubyte();
		val |= (b & 0x7f) << shift;
		shift += 7;
		if ((b & 0x80) == 0)
			break;
	}

	if (shift < size && (b & 0x40) != 0) val |= -(1 << shift);
	return val;
}

enum TagEncoding : ULEB128 {
	arrayType = 0x01,
	classType = 0x02,
	entryPoint = 0x03,
	enumerationType = 0x04,
	formalParameter = 0x05,
	importedDeclaration = 0x08,
	label = 0x0a,
	lexicalBlock = 0x0b,
	member = 0x0d,
	pointerType = 0x0f,
	referenceType = 0x10,
	compileUnit = 0x11,
	stringType = 0x12,
	structureType = 0x13,
	subroutineType = 0x15,
	typedef_ = 0x16,
	unionType = 0x17,
	unspecifiedParameters = 0x18,
	variant = 0x19,
	commonBlock = 0x1a,
	commonInclusion = 0x1b,
	inheritance = 0x1c,
	inlinedSubroutine = 0x1d,
	module_ = 0x1e,
	ptrToMemberType = 0x1f,
	setType = 0x20,
	subrangeType = 0x21,
	withStmt = 0x22,
	accessDeclaration = 0x23,
	baseType = 0x24,
	catchBlock = 0x25,
	constType = 0x26,
	constant = 0x27,
	enumerator = 0x28,
	fileType = 0x29,
	friend = 0x2a,
	namelist = 0x2b,
	namelistItem = 0x2c,
	packedType = 0x2d,
	subprogram = 0x2e,
	templateTypeParameter = 0x2f,
	templateValueParameter = 0x30,
	thrownType = 0x31,
	tryBlock = 0x32,
	variantPart = 0x33,
	variable = 0x34,
	volatileType = 0x35,

	// added in dwarf 3 {
	dwarfProcedure = 0x36,
	restrictType = 0x37,
	interfaceType = 0x38,
	namespace = 0x39,
	importedModule = 0x3a,
	unspecifiedType = 0x3b,
	partialUnit = 0x3c,
	importedUnit = 0x3d,
	condition = 0x3f,
	sharedType = 0x40,
	// } end in dwarf 3

	loUser = 0x4080,
	hiUser = 0xffff,
}

enum AttributeName : ULEB128 {
	sibling = 0x01,
	location = 0x02,
	name = 0x03,
	ordering = 0x09,
	byteSize = 0x0b,
	bitOffset = 0x0c,
	bitSize = 0x0d,
	stmtList = 0x10,
	lowPC = 0x11,
	highPC = 0x12,
	language = 0x13,
	discr = 0x15,
	discrValue = 0x16,
	visibility = 0x17,
	import_ = 0x18,
	stringLength = 0x19,
	commonReference = 0x1a,
	compDir = 0x1b,
	constValue = 0x1c,
	containingType = 0x1d,
	defaultValue = 0x1e,
	inline = 0x20,
	isOptional = 0x21,
	lowerBound = 0x22,
	producer = 0x25,
	prototyped = 0x27,
	returnAddr = 0x2a,
	startScope = 0x2c,
	bitStride = 0x2e,
	upperBound = 0x2f,
	abstractOrigin = 0x31,
	accessibility = 0x32,
	addressClass = 0x33,
	artificial = 0x34,
	baseTypes = 0x35,
	callingConvention = 0x36,
	count = 0x37,
	dataMemberLocation = 0x38,
	declColumn = 0x39,
	declFile = 0x3a,
	declLine = 0x3b,
	declaration = 0x3c,
	discrList = 0x3d,
	encoding = 0x3e,
	external = 0x3f,
	frameBase = 0x40,
	friend = 0x41,
	identifierCase = 0x42,
	macroInfo = 0x43,
	namelistItem = 0x44,
	priority = 0x45,
	segment = 0x46,
	specification = 0x47,
	staticLink = 0x48,
	type = 0x49,
	useLocation = 0x4a,
	variableParameter = 0x4b,
	virtuality = 0x4c,
	vtableElemLocation = 0x4d,

	// added in dwarf 3 {
	allocated = 0x4e,
	associated = 0x4f,
	dataLocation = 0x50,
	byteStride = 0x51,
	entryPc = 0x52,
	useUTF8 = 0x53,
	extension = 0x54,
	ranges = 0x55,
	trampoline = 0x56,
	callColumn = 0x57,
	callFile = 0x58,
	callLine = 0x59,
	description = 0x5a,
	binaryScale = 0x5b,
	decimalScale = 0x5c,
	small = 0x5d,
	decimalSign = 0x5e,
	digitCount = 0x5f,
	pictureString = 0x60,
	mutable = 0x61,
	threadsScaled = 0x62,
	explicit = 0x63,
	objectPointer = 0x64,
	endianity = 0x65,
	elemental = 0x66,
	pure_ = 0x67,
	recursive = 0x68,
	// } end in dwarf 3

	loUser = 0x2000,
	hiUser = 0x3fff,
}

enum AttributeForm : ULEB128 {
	addr = 0x01,
	block2 = 0x03,
	block4 = 0x04,
	data2 = 0x05,
	data4 = 0x06,
	data8 = 0x07,
	string_ = 0x08,
	block = 0x09,
	block1 = 0x0a,
	data1 = 0x0b,
	flag = 0x0c,
	sdata = 0x0d,
	strp = 0x0e,
	udata = 0x0f,
	refAddr = 0x10,
	ref1 = 0x11,
	ref2 = 0x12,
	ref4 = 0x13,
	ref8 = 0x14,
	refUdata = 0x15,
	indirect = 0x16,
}
