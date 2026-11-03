# engram — persistent memory for AI coding agents (SQLite + FTS5, MIT).
# Not in nixpkgs (only engrampa/geogram match the name), so we pin the upstream
# release tarball. The binary is fully static Go, so no autoPatchelfHook needed.
{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "engram";
  version = "3.6.1";

  src = fetchurl {
    url = "https://github.com/Gentleman-Programming/engram/releases/download/v${finalAttrs.version}/engram_${finalAttrs.version}_linux_amd64.tar.gz";
    hash = "sha256-sG1kNs5cfx6Di57EVIcOfsnls+D4m27cXl0uQf4T7c8=";
  };

  # The tarball has no top-level directory (engram + tools/ sit at the root),
  # which the default unpackPhase refuses to cd into — unpack in place instead.
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 engram "$out/bin/engram"
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/engram" --version | grep -q "${finalAttrs.version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Persistent memory for AI coding agents (SQLite + FTS5, MCP server)";
    homepage = "https://github.com/Gentleman-Programming/engram";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "engram";
  };
})
