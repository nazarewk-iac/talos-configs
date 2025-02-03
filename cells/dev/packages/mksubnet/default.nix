{pkgs, ...}:
pkgs.writers.writePython3Bin "mksubnet"
{
  libraries = with pkgs.python3Packages; [
  ];

  flakeIgnore = [
    "E501" # line too long
  ];
}
(builtins.readFile ./mksubnet.py)
