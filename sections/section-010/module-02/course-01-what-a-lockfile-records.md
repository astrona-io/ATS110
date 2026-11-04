# What A Lockfile Records

A `package.json` file lists the packages an app wants and the versions it accepts. It does not say which versions were installed. Two installs from the same `package.json` can give different results, and a lockfile is the file that removes that difference. This part explains version ranges first, then what the lockfile adds.

## Version ranges

Every entry in `dependencies` has a version or a range. npm follows the semantic versioning rules: a version has three numbers, `major.minor.patch`, and a range says which of them may change.

| Entry | Accepts |
| --- | --- |
| `"1.2.3"` | Only 1.2.3 |
| `"^1.2.3"` | 1.2.3 up to, but not including, 2.0.0 |
| `"~1.2.3"` | 1.2.3 up to, but not including, 1.3.0 |
| `">=1.2.3"` | 1.2.3 and everything newer |

The caret `^` has a special rule for versions that start with 0. For a `0.x` version, the first non-zero number is treated as the major one. `^0.54.0` therefore accepts `0.54.0` up to, but not including, `0.55.0`, and `^0.0.3` accepts only `0.0.3`. All the `@perses-dev` packages are `0.x` versions, so a caret on them allows patch releases of one minor version, and nothing else.

That still matters. A patch release is allowed to change behavior, and the Perses packages have their peer dependency ranges set against the minor version. Two machines that install on different days can end up with different patch versions of the same package.

Ask the registry which versions of a package exist, and compare them with a range. `npm view` reads the registry directly:

<!-- astrona:playground:renew -->

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
builder "npm view @perses-dev/components versions --json | tail -n 12"
```

The last twelve lines are the newest published versions. Find the highest `0.54.x` in the list; that is what `^0.54.0` would install today.

## What the lockfile adds

When `npm install` finishes, it writes `package-lock.json` next to `package.json`. The file is JSON, and it records the whole tree that npm installed, not only the packages you listed. Print the start of it:

```sh
builder "head -n 40 package-lock.json"
```

Three fields at the top are worth knowing. `lockfileVersion` is the format version; npm 9 and later, including the npm that ships with Node.js 22, write version 3. Check it in your own output. `packages` is a map from a path to a description of one installed package. The first key, an empty string, is the app itself, and its `dependencies` copy what `package.json` says. Every other key is a path such as `node_modules/@perses-dev/components`, and each entry holds the exact `version`, the `resolved` address of the tarball in the registry, and an `integrity` value.

Read one entry:

```sh
builder "node -e \"const l=require('./package-lock.json');console.log(JSON.stringify(l.packages['node_modules/@perses-dev/components'],null,2))\""
```

The `integrity` value is a hash of the tarball. When npm installs from the lockfile, it checks the downloaded file against that hash and stops if they differ, so a package that changed on the registry under the same version number is detected. The entry also lists the package's own `dependencies` and `peerDependencies`.

## A nested path means a second copy

The key of an entry shows where the package sits on disk. `node_modules/lodash` is the copy at the top level, which every package can reach. A key such as `node_modules/some-package/node_modules/lodash` is a second copy, installed inside `some-package` because that package needed a version the top-level copy does not satisfy. Count the nested copies of a package by searching the keys:

```sh
builder "node -e \"const l=require('./package-lock.json');console.log(Object.keys(l.packages).filter(k=>k.endsWith('node_modules/react')))\""
```

For React, the list must have exactly one path. Later in this module you will do the same check with better tools.

## What goes into the repository

Commit `package-lock.json` together with `package.json`. A lockfile that is not committed protects nobody. Do not edit it by hand: a change to a version, a hash or a path is easy to get wrong, and npm rewrites the file whenever you run `npm install`.

The lockfile must also stay in step with `package.json`. When you change a version in `package.json`, run `npm install` once to update the lockfile, and commit both files in the same change.

## Common pitfalls

> [!WARNING]
> - **Reading a caret as "the version I wrote".** `^0.54.0` is a range. The lockfile holds the version that was actually installed.
> - **Expecting `^0.54.0` to accept `0.55.0`.** On a `0.x` version the caret stops at the next minor version.
> - **Leaving the lockfile out of the repository.** Every machine then resolves the ranges again.
> - **Editing the lockfile by hand.** Change `package.json` and let npm write the lockfile.
