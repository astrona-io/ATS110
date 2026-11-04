# Overrides And Upgrading With The Server

Sometimes `npm explain` shows that a package you do not control asks for a version you know is wrong, and no change to your own file fixes it. npm has a field for that case, `overrides`. This part explains the field and its risk, then gives the order of steps for moving the whole app to a new Perses release.

## The overrides field

`overrides` is an object in the top level of `package.json`. It tells npm to use a version you name for a package, wherever in the tree the package is requested. The simplest form is a package name and a version:

```json
{
  "overrides": {
    "lodash": "4.18.1"
  }
}
```

Every request for `lodash`, from your app or from any package under it, now resolves to `4.18.1`. You can limit the rule to the children of one package by nesting it:

```json
{
  "overrides": {
    "some-package": {
      "lodash": "4.18.1"
    }
  }
}
```

Here only the `lodash` that `some-package` needs is changed. Overrides need npm 8.3 or later; the builder has npm 10.

Set one with `npm pkg set`, which edits `package.json` without a text editor, then install and read what changed:

<!-- astrona:playground:renew -->

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
builder npm pkg set overrides.lodash=4.18.1
builder npm install --no-audit --no-fund
builder npm ls lodash
```

The lines for `lodash` now carry the marker `overridden`. Remove the override again when you are done:

```sh
builder npm pkg delete overrides
builder npm install --no-audit --no-fund
```

## The risk of an override

An override replaces a decision that the package's authors made. If a package asks for `^2.0.0` and you force `1.9.0`, you run it against a version it was never tested with. This is the same risk as `--legacy-peer-deps`, but limited to one package, and written in a file where a reviewer can see it.

Use an override only when all three are true: you know why the package asks for that version, you have a reason to believe the forced version works, and you can describe the reason in the commit message. Do not use an override on a `@perses-dev` package. Those packages must be released together, and an override that mixes them gives exactly the mismatch that this section is about. If a `@perses-dev` package is wrong, change your own `package.json`.

## Upgrading the app with the server

A new Perses release changes more than one number. The shared packages, the plugin versions and the server must move together. Do the steps in this order and stop at the first one that fails:

1. **Read the release notes** of the new Perses version for changes to the embedding API, and note the new version, for example `0.55.0`.
2. **Find the plugin versions of that release.** Install the new server or read its `/api/v1/plugins` list, and write down `Prometheus`, `TimeSeriesChart` and `StatChart`. Never guess them from the newest version on npm.
3. **Find the `@perses-dev/spec` version.** Read what the new `@perses-dev/dashboards` asks for:

   ```sh
   builder npm view @perses-dev/dashboards@0.55.0 dependencies
   ```

4. **Change `package.json` as one edit.** Set the five shared packages to the new version, set the three plugins, and set `spec` to the version from the previous step.
5. **Install.** Run `npm install` once to write the new lockfile. If npm reports `ERESOLVE`, read the message; do not force it.
6. **Check the tree.** Run `npm ls --all` and make sure each shared package appears once.
7. **Check the types.** Run `npm run typecheck`. A type error shows which call changed in the new API.
8. **Build, deploy and test.** Request the script and the proxy path as described in the first module.
9. **Upgrade the server.** Change the Helm chart version and apply it. Check that the app still gets data.

If the new set does not work, go back to the old one. Because both `package.json` and `package-lock.json` are committed, reverting both files and running `npm ci` restores the previous tree exactly. The lockfile is what makes the roll-back certain.

## Keeping a record

Write the set of versions that belong together somewhere a teammate will see it: in the README of the app or in a comment in the pull request. A short table is enough: the Perses version, the shared package version, the three plugin versions and the `spec` version. When someone asks why the app uses `prometheus-plugin` 0.58.0, the answer is a line in a file and not a conversation.

You can now keep an install repeatable, find a copy that should not be there, and move the app to a new release in a safe order. The lab uses the first of these on an app that has ranges and no lockfile.

## Common pitfalls

> [!WARNING]
> - **Overriding a `@perses-dev` package.** Change your own `package.json` instead; the packages are released as a set.
> - **Leaving an override in place after the cause is gone.** Review overrides at every upgrade.
> - **Upgrading the packages and not the server, or the other way round.** The two must match.
> - **Taking the plugin versions from npm.** Take them from the server's `/api/v1/plugins` list.

## Your mission: Make The Install Reproducible

You can now read version ranges, create and use a lockfile, and make npm save exact versions. The graded lab gives you an app that uses ranges and has no lockfile, and asks you to make the install exact and repeatable, and to serve a working build.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-110-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-110-lab-010-02
astrona start ats-110-playground-010-02
```
