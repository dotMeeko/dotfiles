# Dotter

[Dotter](https://github.com/SuperCuber/dotter) needs a **local** config (`.dotter/local.toml`). The [wiki](https://github.com/SuperCuber/dotter/wiki/1.-Getting-Started) recommends **gitignoring** it because it is machine-specific; a fresh **`git clone` therefore has no `local.toml`**, and `dotter deploy` fails until it exists (`dotter init` also creates it).

This repo keeps **`.dotter/local.toml.example`** in git. **`./scripts/macos/bootstrap.sh`** copies it to **`.dotter/local.toml`** when that file is missing, so bootstrap + deploy works on a new machine.

If you skip bootstrap, run once:

```bash
cp .dotter/local.toml.example .dotter/local.toml
```

Then:

```bash
dotter deploy --dry-run -v
dotter deploy -v
```

Use **`-f`** if targets already exist as plain files. Full wiki index: [SuperCuber/dotter/wiki](https://github.com/SuperCuber/dotter/wiki).
