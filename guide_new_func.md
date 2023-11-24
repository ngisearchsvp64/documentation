Copy respective test from glibc
Go to string/test-[func name]

- From glibc, copy the test C file for the respective function
into svp64-port directory.
It should be under the function category, for example, memrchr is
under `string/test-memrchr.c`
- Copy `[function]_wrapper.c` and make adjustments as needed.
- 
