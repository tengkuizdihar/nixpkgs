{ lib, stdenv, autoconf, automake, intltool, libtool, fetchFromGitHub, readline, gameconqueror ? false }:

stdenv.mkDerivation rec {
  version = "0.17";
  pname = "scanmem";

  src = fetchFromGitHub {
    owner = "scanmem";
    repo = "scanmem";
    rev = "v${version}";
    sha256 = "17p8sh0rj8yqz36ria5bp48c8523zzw3y9g8sbm2jwq7sc27i7s9";
  };

  nativeBuildInputs = [ autoconf automake intltool libtool ];
  buildInputs = [ readline ];

  configurePhase =
    lib.concatStringsSep "\n" ([
      "./autogen.sh"
      (optionalString gameconqueror "./configure --prefix=$out --enable-gui")
    ]);

  meta = with lib;
    {
      homepage = "https://github.com/scanmem/scanmem";
      description = "Memory scanner for finding and poking addresses in executing processes";
      maintainers = [ ];
      platforms = platforms.linux;
      license = licenses.gpl3;
    };
}
