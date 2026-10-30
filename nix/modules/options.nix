# Custom options set per machine by the installer (generated user.nix).
{ lib, ... }:
{
  options.my.username = lib.mkOption {
    type = lib.types.str;
    default = "meeko";
    description = "Primary user login name (chosen at install time).";
  };

  options.my.fullName = lib.mkOption {
    type = lib.types.str;
    default = "";
    description = "Human-readable full name (GECOS), shown on the login screen. Optional.";
  };
}
