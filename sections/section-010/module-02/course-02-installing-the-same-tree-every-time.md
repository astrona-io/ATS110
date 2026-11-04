# Installing The Same Tree Every Time

With a lockfile in place, there are two ways to install, and they behave differently. This part explains `npm install` and `npm ci`, then the `.npmrc` file that decides how npm saves versions, and what to keep in mind when the install runs inside a builder pod.

## npm install and npm ci

`npm install` with no package name reads `package.json`, looks at the lockfile, and installs. If the lockfile already satisfies `package.json`, npm uses the locked versions. If `package.json` asks for something the lockfile does not satisfy, npm resolves the difference and **writes the lockfile again**. So `npm install` can change the lockfile.

`npm ci` is built for repeatable builds. It needs a lockfile and fails if there is none. It first deletes `node_modules`, then installs exactly what the lockfile lists, and it never writes to `package.json` or `package-lock.json`. If `package.json` and the lockfile disagree, it stops with an error instead of resolving the difference.

Try the second behavior. Change one version so the two files disagree, and run `npm ci`:

<!-- astrona:playground:renew -->

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
builder "sed -i 's/\"echarts\": \"5.5.0\"/\"echarts\": \"5.6.0\"/' package.json"
builder npm ci --no-audit --no-fund
```

npm stops with an error that says `package.json` and `package-lock.json` are not in sync. The message names the package whose version differs. Put the version back and run the install again:

```sh
builder "sed -i 's/\"echarts\": \"5.6.0\"/\"echarts\": \"5.5.0\"/' package.json"
builder npm ci --no-audit --no-fund
```

This time `npm ci` removes `node_modules` and installs the tree from the lockfile. Use it in every automated build. Use `npm install` on a developer machine when you intentionally change versions.

| Situation | Command |
| --- | --- |
| Automated build, deploy pipeline | `npm ci` |
| You edited `package.json` and want a new lockfile | `npm install` |
| You want to update only the lockfile, without touching `node_modules` | `npm install --package-lock-only` |
| You added one package | `npm install name` |

## Where the lockfile lives in the cluster

The builder pod keeps `/workspace/app` on an `emptyDir` volume, so a new pod starts from the files in the ConfigMap `app-source` again. A lockfile that exists only in the pod is lost with the pod. To keep it, copy it out of the pod and into the source folder that creates the ConfigMap:

```sh
kubectl -n embed exec deploy/app-builder -- cat /workspace/app/package-lock.json > package-lock.json
```

Put `package-lock.json` in the folder that holds `package.json`, and the next ConfigMap carries both. From then on a restarted builder can run `npm ci` and reach the same tree.

## The .npmrc file

npm reads its settings from several files, and from the command line. The most specific wins:

1. command-line flags
2. the project `.npmrc`, next to `package.json`
3. the user `.npmrc`, in the home directory
4. the global `.npmrc`
5. npm's built-in defaults

A project `.npmrc` is the place for settings that belong to the project, because it is committed with the code. One setting matters here: `save-exact`. By default, `npm install name` saves `"name": "^1.2.3"`. With `save-exact=true`, it saves `"name": "1.2.3"`.

Create the file, then ask npm which value is active:

```sh
builder "echo 'save-exact=true' > .npmrc"
builder npm config get save-exact
```

The answer is `true`. Print all non-default settings with `npm config list`; the project file is named at the top of the output, and the settings from it are listed below.

Add a package to see the effect, then remove it again:

```sh
builder npm install --no-audit --no-fund --save-dev prettier@3.3.3
builder "grep prettier package.json"
builder npm uninstall --no-audit --no-fund prettier
```

The line in `devDependencies` reads `"prettier": "3.3.3"`, with no caret. The uninstall restores `package.json` and the lockfile.

Never put `legacy-peer-deps=true` in `.npmrc`. It turns the peer dependency check off for every install in the project, and the `ERESOLVE` error that would have told you about a version problem is gone.

## Pin the Node.js and npm versions too

The same lockfile can give different results on different Node.js versions, because some packages choose files by the Node.js version. The builder pod runs Node.js 22. Record that in `package.json` with the `engines` field:

```sh
builder node --version
builder npm --version
builder "npm pkg set engines.node='>=22'"
```

By default npm only warns when `engines` is not satisfied. Add `engine-strict=true` to `.npmrc` if you want the install to fail instead. For this module a warning is enough.

## Common pitfalls

> [!WARNING]
> - **Using `npm install` in a build pipeline.** It can rewrite the lockfile. Use `npm ci`.
> - **Running `npm ci` and expecting it to fix a mismatch.** It only reports it. Run `npm install` where you edit, and commit the lockfile.
> - **Keeping the lockfile only in the pod.** The `emptyDir` volume is gone when the pod is replaced.
> - **Putting `save-exact` only in your user `.npmrc`.** Your teammates and your build do not have it. Use the project file.
