# Section 010: The Perses npm Packages

The Perses user interface is not one closed application. It is built from npm packages that anyone can install: the same code that draws a panel in Perses can draw it in your own web application. Before you can embed a panel or write a plugin, you need to know what those packages are and how to install a set of them that works together.

This section covers exactly that. It explains what each `@perses-dev` package contains and how the packages sit on top of each other, why their versions must match the Perses server and each other, and how to build and serve a small React application from them inside the cluster.

**Topic covered:** the Perses npm packages

## What you will learn

- The `@perses-dev` packages and their layers, from `@perses-dev/spec` up to `@perses-dev/dashboards`, and why `@perses-dev/core` is deprecated.
- Which plugin package versions ship with Perses v0.54.0.
- What a peer dependency is, how npm reports a conflict, and why `--legacy-peer-deps` hides problems instead of fixing them.
- Reading the installed tree with `npm ls`.
- Building a React application with Vite in a builder pod and serving it with nginx.

## The learning path

The module starts at its landing page, which also launches the playground. The playground has Perses, Prometheus, a builder pod with a small React application, and an nginx server that shows it.

### 1. Use The Perses npm Packages

1. What Is In The Perses npm Packages
2. Versions And Peer Dependencies
3. Building The App In The Cluster, followed by the lab **Align The Perses Package Versions**
4. Summary

## Section capstone: Rescue A Starter App That Never Built

A colleague started an application from a template, upgraded a few packages to the newest versions, and changed the build configuration. Now `npm install` fails, and when it is forced through, the page stays blank. The capstone combines everything in the module: versions, peer dependencies and the build. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-110-capstone-010
```
