# Summary

`package.json` lists the versions an app accepts, and `package-lock.json` records the versions npm installed, including every package below the ones you listed. A caret range accepts newer versions inside one major version, and on a `0.x` version, which every `@perses-dev` package is, only newer patch versions of the same minor. Each lockfile entry stores the exact version, the address of the tarball and a hash, so npm detects a changed package. The key of an entry shows where it sits: a path with a second `node_modules` in it is a second copy.

`npm install` can rewrite the lockfile. `npm ci` needs the lockfile, deletes `node_modules`, installs exactly what the lockfile lists, never writes either file, and stops when `package.json` and the lockfile disagree. Use `npm ci` in automated builds, and `npm install` where you edit. A project `.npmrc` with `save-exact=true` makes npm save exact versions, and settings from the project file win over the user and global files. `legacy-peer-deps` does not belong in it. In the cluster, the builder's volume is lost with the pod, so copy the lockfile out of the pod and keep it with the source.

Two copies of a stateful package such as React or `@perses-dev/plugin-system` break the page. `npm ls name --all` shows every path to a package with the markers `deduped`, `invalid`, `missing`, `extraneous` and `overridden`; `npm explain name` shows why a copy is installed; `npm dedupe` merges copies when the ranges allow it. The `overrides` field forces a version for one package, and it carries the same kind of risk as forcing peers, so use it rarely and never on a `@perses-dev` package. A few facts to keep:

- Commit `package.json` and `package-lock.json` together, and never edit the lockfile by hand.
- Use `npm ci` in builds, `npm install` to change versions, and `save-exact=true` in the project `.npmrc`.
- Check `npm ls --all` for duplicates of `react`, `react-dom` and every `@perses-dev` package.
- Upgrade in order: plugin versions from the new server, one `package.json` edit, install, `npm ls`, type check, build, then the server.
- Reverting both files and running `npm ci` restores the previous tree.

<!-- astrona:playground:destroy -->
