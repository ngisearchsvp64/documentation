# Setting up the environment for working with glibc tests

## Setting up the LibreSOC chroot

Create LibreSOC chroot (host system)

    #: cd /PATH/TO/dev-env-setup
    #: ./mk-deb-chroot glibc-svp64
    #: ./cp-scripts-to-chroot glibc-svp64

Scripts inside chroot:

    $: schroot -c glibc-svp64
    (glibc-svp64)$: cd ~/dev-env-setup
    (glibc-svp64)$: sudo bash
    (glibc-svp64)#: ./install-hdl-apt-reqs
    (glibc-svp64)#: ./binutils-gdb-install
    (glibc-svp64)#: ./hdl-dev-repos

Copy over the repo for glibc svp64 work: - TODO: will change to proper repos later

    (glibc-svp64)$: cd ~/src/

## Workaround with repo's outdated SSL certificate - Remove once fixed

Using the GIT_SSL_NO_VERIFY env var worked for me:

    (glibc-svp64)$: GIT_SSL_NO_VERIFY=true git clone http://git.vectorcamp.gr/VectorCamp/glibc-svp64
    (glibc-svp64)$: cd glibc-svp64
    (glibc-svp64)$: git submodule update --init --recursive

Disable SSL verification:

    (glibc-svp64)$: git config http.sslverify false

## Running the comprehensive memchr test (no SVP64)

Build the tests

    (glibc-svp64)$: ./buildglibc.sh

To run the comprehensive test on memchr (not SVP64, only powerisa assembler):

    (glibc-svp64)$: cd svp64-port
    (glibc-svp64)$: make all
    (glibc-svp64)$: SILENCELOG=1 ./test-memchr-svp64 --direct
    (glibc-svp64)$: SILENCELOG='!instr_in_outs' ./test-memchr-svp64 --direct


Started test at 2023-10-27 21:09 (UTC+1)
Test finished at: 2023-10-28 03:52 (UTC+1)

Once the full test finishes (takes between 4h and 8h), there should be no warning or errors. 
