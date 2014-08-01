elf-d
------------

Reads 32-bit and 64-bit elf binary files.

How to run example
------------

Run `dub run elf-d:example` in the parent directory.

Features
------------

- Read general elf file properties like file class, abi version, machine isa, ...
- Parse elf sections
- Read elf symbol and section string tables
- Read DWARF line program tables and produce address info (.debug_line section)

TODOs
------------

- Fix endianness issue (currently only native endianness is supported).
- Add interpretation for more sections.

License
------------

Licensed under Boost. Check accompanying file LICENSE_1_0.txt or copy at
http://www.boost.org/LICENSE_1_0.txt

