# Use The Perses npm Packages

A dashboard server is useful, but sometimes the dashboard has to live somewhere else: inside an internal portal, a product's admin page, or an incident tool. Perses supports this directly. Its user interface is published as a set of npm packages, and an npm package is a versioned bundle of JavaScript code that any project can install from the npm registry.

This module is about those packages. Keep one sentence in mind: **the packages, their plugins and the Perses server must come from the same release.** Most problems people meet when they first embed Perses come from mixing versions, and npm reports them as peer dependency errors that are easy to misread.

The module has three parts. **What Is In The Perses npm Packages** names each package and shows how they depend on each other. **Versions And Peer Dependencies** explains how to choose versions that fit Perses v0.54.0, and how to read the tree npm installed. **Building The App In The Cluster** builds a small React application with those packages and serves it with nginx. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Name the `@perses-dev` packages and say what each one contains.
- Explain why `@perses-dev/core` should not be used in new code.
- Find the plugin package versions that ship with a Perses release.
- Explain what a peer dependency is and read an npm `ERESOLVE` error.
- Check an installed tree with `npm ls` and spot two copies of one package.
- Build a React application with Vite in a builder pod and serve it with nginx.

## Before you start

You need Kubernetes basics: namespaces, pods, ConfigMaps, `kubectl exec` and `kubectl logs`. You should be able to read a `package.json` file and a short TypeScript file. You do not need Node.js on your machine.

Your playground is a single-node `kind` cluster with these parts:

| Part | Where | What it is |
| --- | --- | --- |
| Perses v0.54.0 | namespace `perses` | The dashboard server, with the project `inventory` and the global datasource `prometheus` |
| Prometheus | namespace `observability` | The metrics server the datasource points at |
| `app-builder` | namespace `embed` | A pod with Node.js 22; the example app is in `/workspace/app` |
| `embed-app` | namespace `embed` | nginx; it serves the built app and forwards `/api/` and `/proxy/` to Perses |

The playground has already installed the app's packages, built it once and deployed it, so you can see a working result before you change anything. Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
