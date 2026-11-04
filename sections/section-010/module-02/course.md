# Keep The Dependencies Reproducible

An app that builds today and fails next month, with no change to its code, is a common problem in JavaScript projects. The cause is almost always the same: the project asks npm for version ranges, and npm picks whatever is newest inside the range on the day of the install. For an app built from Perses packages, where the versions have to fit the Perses server, that is a real risk.

This module is about taking that choice away from npm. Keep one sentence in mind: **`package.json` says what you want, the lockfile says what you got, and `npm ci` installs exactly the lockfile.**

The module has four parts. **What A Lockfile Records** explains version ranges and the file that fixes them. **Installing The Same Tree Every Time** shows `npm ci`, the `.npmrc` file and the settings that decide how npm saves versions. **Finding Duplicate And Wrong Copies** uses `npm ls` and `npm explain` to find out where a package came from. **Overrides And Upgrading With The Server** forces a version when you must, and gives you a procedure for moving the whole set to a new Perses release. A graded lab follows the fourth part.

## Learning objectives

After this module you can:

- Read a version range and say which versions it accepts, including a range on a `0.x` version.
- Explain what `package-lock.json` records and why it is committed to the repository.
- Say how `npm install` and `npm ci` differ, and when to use each.
- Make npm save exact versions with a project `.npmrc` file.
- Find every copy of a package with `npm ls`, and the reason it is there with `npm explain`.
- Use the `overrides` field, and say what risk it carries.
- Move the app to a new Perses release in a fixed order.

## Before you start

You should have finished the first module of this section, or know what a peer dependency is. You need `kubectl exec` and a short `package.json` file. You do not need Node.js on your machine.

Your playground is the same cluster as in the first module: Perses v0.54.0, Prometheus, the builder pod `app-builder` with the app in `/workspace/app`, and the nginx server `embed-app`. The app was installed once with `npm install`, so a lockfile already exists in it. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
