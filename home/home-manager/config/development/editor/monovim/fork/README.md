# Monovim framework sources

Monovim vendors and maintains renamed forks of the NvChad framework, its UI,
and Base46 color engine. These Lua modules ship inside Monovim's Nix-built
runtime; the editor does not download or load NvChad at runtime.

Upstream sources used for this fork:

- NvChad framework `87d6a41ec07ab995de912a892749b6b4805ad2b3` (v2.5)
- NvChad UI `f297bfb60c7e4a4a833f2837be79e04df2873c6a` (v3.0)
- Base46 `d870ec89a7b2f28c4accce515f97b7bcc5b9d200` (v3.0)

The source namespaces and configuration model have been renamed for Monovim.
Each upstream project is GPL-3.0; Base46 also includes its separately
licensed base16 component. The corresponding license texts are in `licenses/`.
