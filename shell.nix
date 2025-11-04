{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell { 
  packages = with pkgs; [ ]; 
  buildInputs = with pkgs; [ libllvm libclang protobuf clang gcc openssl lz4 ];
  nativeBuildInputs = with pkgs; [ pkg-config udev rustc cargo ];

  LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
  BINDGEN_EXTRA_CLANG_ARGS = 
    # Include path for C++ stdlib headers
    "-I${pkgs.stdenv.cc.cc}/include/c++/${pkgs.stdenv.cc.cc.version} " +
    # Include path for C++ target-specific headers  
    "-I${pkgs.stdenv.cc.cc}/include/c++/${pkgs.stdenv.cc.cc.version}/${pkgs.stdenv.hostPlatform.config} " +
    # Include path for GCC headers
    "-I${pkgs.stdenv.cc.cc}/lib/gcc/${pkgs.stdenv.hostPlatform.config}/${pkgs.stdenv.cc.cc.version}/include " +
    # Include path for C standard library headers
    "-I${pkgs.glibc.dev}/include";

  # Some crates (like protobuf-src, lz4-sys) force CC=clang, so we need to ensure clang can find headers
  # Use the stdenv which provides properly wrapped compilers
  CC = "${pkgs.stdenv.cc}/bin/cc";
  CXX = "${pkgs.stdenv.cc}/bin/c++";
  PROTOC = "${pkgs.protobuf}/bin/protoc";
  
  # When cc crate uses clang, it needs to know where to find system headers
  # Point to clang's resource dir for compiler intrinsics, glibc for standard C headers, and udev for libudev.h
  CFLAGS = "-isystem ${pkgs.llvmPackages.libclang.lib}/lib/clang/${pkgs.lib.versions.major pkgs.llvmPackages.libclang.version}/include -isystem ${pkgs.glibc.dev}/include -isystem ${pkgs.systemd.dev}/include";
  
  # Linker also needs to know where to find libraries and CRT objects
  # -B tells the linker where to search for CRT object files (crt1.o, crti.o, etc.)
  LDFLAGS = "-L${pkgs.glibc}/lib -L${pkgs.gcc.cc.lib}/lib -L${pkgs.stdenv.cc.cc}/lib/gcc/${pkgs.stdenv.hostPlatform.config}/${pkgs.stdenv.cc.cc.version} -B${pkgs.glibc}/lib -B${pkgs.gcc.cc}/lib/gcc/${pkgs.stdenv.hostPlatform.config}/${pkgs.gcc.cc.version}";
  
  # Tell openssl-sys to use the system OpenSSL instead of building from source
  OPENSSL_DIR = "${pkgs.openssl.dev}";
  OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
  OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
  OPENSSL_NO_VENDOR = "1";

  # Print key env vars when entering the shell so you can verify they're set correctly
  shellHook = ''
    echo "shell.nix: CC=$CC" 
    echo "shell.nix: CXX=$CXX" 
    echo "shell.nix: PROTOC=$PROTOC"
    echo "shell.nix: OPENSSL_DIR=$OPENSSL_DIR"
    echo "shell.nix: Using stdenv compiler wrapper which handles all paths automatically"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔨 Solfuzz-agave Development Environment"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Read to build! Run:"
    echo "  make build"
  '';

  # Tell librocksdb-sys to use the system RocksDB instead of building from source
  ROCKSDB_LIB_DIR = "${pkgs.rocksdb}/lib";
  ROCKSDB_INCLUDE_DIR = "${pkgs.rocksdb}/include";
  
  # Tell tikv-jemalloc-sys to use the system jemalloc instead of building from source
  JEMALLOC_OVERRIDE = "${pkgs.jemalloc}/lib/libjemalloc.so";
}


