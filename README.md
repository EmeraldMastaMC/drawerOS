# drawerOS
I am writing this so I can learn zig.
## The name
I decided the name from a random noun generator.
## Comments
"the manual" refers to AMD64 Architecture Programmer's Manual Volume 2.
# Using drawerOS
## Building
The build dependencies are:
- `gcc`
- `ld`
- `as`
To build the operating system, run: `make -B`
## Running
The run dependencies are:
- `qemu`
You Must be able to run using KVM to run for yourself
I have only tested this on linux as the host
To run the operating system using QEMU, run: `make run` 
