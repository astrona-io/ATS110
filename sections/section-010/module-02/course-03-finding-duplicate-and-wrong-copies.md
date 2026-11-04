# Finding Duplicate And Wrong Copies

When a Perses panel fails with a message about a missing plugin or a missing context, the cause is often not in your code. It is a second copy of a shared package in `node_modules`. This part teaches two npm commands that find such copies and explain why they are there, and what to do about them.

## Why two copies break an app

A package such as React or `@perses-dev/plugin-system` keeps state in the module itself: React keeps its current component in a variable, and the plugin system keeps its registry. If two copies are installed, the application imports one and a library imports the other. A component then reads context from a provider that lives in the other copy, and finds nothing. Two copies of `@perses-dev/plugin-system` mean two plugin registries: the panel looks up `TimeSeriesChart` in the one that has no plugins.

npm installs a second copy when two packages ask for versions that no single version can satisfy. It then puts one copy at the top level of `node_modules` and the other inside the package that needed it.

## npm ls

`npm ls` prints the installed tree. Give it a package name, and it prints only the paths that lead to that package. Run it for React:

<!-- astrona:playground:renew -->

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
builder npm ls react
```

The first line is the app. Below it are the packages that depend on React, each followed by `react@18.3.1`. Read the markers at the end of a line:

| Marker | Meaning |
| --- | --- |
| `deduped` | The package is shared; this line points at a copy that is already listed |
| `invalid` | The installed version does not satisfy what the parent asked for |
| `missing` | A required package is not installed |
| `extraneous` | A package is installed but nothing depends on it |
| `overridden` | An `overrides` rule changed the version |

A healthy tree for React has one version number in every line, and the lines that repeat it are marked `deduped`. A second version number, for example `react@17.0.2`, is a second copy.

`npm ls` also controls its depth. By default it prints only the top level; `--all` prints every level, and `--depth=1` prints one level below the top. Use `--all` to look for a copy that is hidden inside another package:

```sh
builder npm ls @perses-dev/plugin-system --all
```

The exit code is 0 when npm found no problem, and 1 when it did. That makes the command usable in a build script.

## npm explain

`npm ls` shows the tree from the top. `npm explain` (the same command as `npm why`) starts from one installed package and shows every chain of dependencies that led to it. Use it when you ask "why is this here?":

```sh
builder npm explain @perses-dev/components
```

The output starts with the package and the version, and then lists each package that depends on it, with the range it asked for and a line showing whether the dependency is a normal one or a peer. For `@perses-dev/components`, you see your app, which asks for `0.54.0`, and the plugins and packages that have it as a peer dependency. A line like `peer @perses-dev/components@"^0.54.0"` shows which range a package accepts.

Give `npm explain` a path to ask about a specific copy. If a second copy is nested, use the path from the lockfile key:

```sh
builder npm explain node_modules/@perses-dev/components
```

## Find duplicates in the lockfile

The lockfile lists every installed copy. To list every package that has more than one installed version, group the lockfile paths by package name. This script prints the names with more than one copy and the paths of those copies:

```sh
builder "node -e \"const l=require('./package-lock.json');const by={};for(const k of Object.keys(l.packages)){if(!k)continue;const n=k.slice(k.lastIndexOf('node_modules/')+13);(by[n]=by[n]||[]).push(k+'@'+l.packages[k].version)}for(const n in by)if(by[n].length>1)console.log(n,by[n])\""
```

Duplicates of small utility packages are common and mostly harmless. Look only for the packages that keep state: `react`, `react-dom`, `@emotion/react`, `@tanstack/react-query`, and every `@perses-dev/*` package. A duplicate of one of those can break the page.

## Fixing a duplicate

Fix the cause, not the symptom, in this order:

1. **Run `npm dedupe`.** It moves packages up the tree so that one copy satisfies several parents, when the ranges allow it. Check the result with `npm ls` again.
2. **Change the version in `package.json`.** Most duplicates come from a version you pinned that no longer fits a package. `npm explain` names the range the other package accepts.
3. **Use an override**, only when a package forces a version you know is safe. The section on overrides in this module explains this.

Run the dedupe and look at what it changed:

```sh
builder npm dedupe --no-audit --no-fund
builder npm ls --all
echo "exit code: $?"
```

On the healthy example app, `npm dedupe` changes nothing, because there is nothing to merge.

## Common pitfalls

> [!WARNING]
> - **Reading only the top of `npm ls`.** A second copy sits inside another package; use `--all` or give the package name.
> - **Ignoring `invalid` because the build works.** The page can build and still fail when it runs.
> - **Deleting `node_modules` and installing again to fix a duplicate.** With the same `package.json` and lockfile you get the same tree.
> - **Fixing one duplicate by forcing the install.** `--force` and `--legacy-peer-deps` hide the problem and keep the copy.
