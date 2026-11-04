# Checking The App Before And After A Build

A build that finishes without an error is not proof that the page works. A wrong version can build cleanly and fail only in the browser, and a missing file can leave nginx serving HTML where JavaScript should be. This part gives you a short list of checks to run before the build, and a second list to run after the deploy, so a problem is found at the step that caused it.

## Check the packages before you build

Start with the installed tree. `npm ls` prints the dependency tree and ends with a non-zero exit code when it finds a problem such as a missing, invalid or extraneous package. Run it with `--all` to include packages that other packages installed:

<!-- astrona:playground:renew -->

```sh
builder() { kubectl -n embed exec -i deploy/app-builder -- sh -c "cd /workspace/app && $*"; }
builder npm ls --all
echo "exit code: $?"
```

An exit code of 0 means npm found no problem. Any other code means at least one line in the tree is marked `invalid`, `missing` or `extraneous`; read those lines first.

Next, ask npm what it would update. `npm outdated` compares the installed versions with the registry and lists the ones that differ:

```sh
builder npm outdated
```

For this app, the list is not a to-do list. The `@perses-dev` packages and `echarts` are pinned on purpose, so a newer version on the registry is expected and is not an error. Read the columns `Current` and `Wanted` and `Latest`: `Wanted` is the highest version that your `package.json` range allows, and `Latest` is the newest version published. With exact pins, `Current` and `Wanted` match. A difference between them would mean the installed version does not match the file. `npm outdated` ends with exit code 1 when it lists anything, so do not use it as a pass or fail check.

## Check the types before you build

The app's `package.json` has a script called `typecheck` that runs `tsc --noEmit`. TypeScript reads every source file and the type definitions of every package, and reports an error when you call a function with the wrong arguments or use a prop that does not exist. It writes no files:

```sh
builder npm run typecheck
```

This check catches a mistake that the Vite build does not. Vite removes the types and bundles the code without checking them, so a wrong prop passes the build and fails when the page runs. When you upgrade a Perses package, the type check is the fastest way to find which of your calls changed.

## Read the build output

`npm run build` prints each file that Vite wrote with its size. Three things in that output are worth a look. First, an `index.html` and at least one JavaScript file under `dist/assets/` must be there. Second, a size warning for a chunk over 500 kilobytes is normal here, because React, Material UI, ECharts and the Perses packages are all in one file. Third, any line that starts with `error` means the build did not finish, and the old `dist/` folder, if there is one, is not a valid result.

You can check that the Perses code really reached the bundle by searching the built file for a name that only the time series chart module contains:

```sh
builder "grep -l TimeSeriesChart dist/assets/*.js"
```

`grep -l` prints the names of the files that contain the text. If it prints nothing, the chart code is not in the bundle, and the page cannot draw the panel.

## Check what nginx serves after the deploy

Build and deploy, then test the result the way a browser would, from the `tester` pod. First ask nginx for the page and find the script it loads:

```sh
builder "npm run build && npm run deploy"
kubectl -n observability exec deploy/tester -- sh -c \
  'curl -s http://app.localtest.me:8081/ | grep -o "src=\"/assets/[^\"]*\""'
```

The output is one `src="/assets/..."` attribute with the file name Vite chose. Ask nginx for that file and print the status code and the content type:

```sh
kubectl -n observability exec deploy/tester -- curl -s -o /dev/null \
  -w '%{http_code} %{content_type}\n' http://app.localtest.me:8081/assets/NAME.js
```

Replace `NAME.js` with the file name from the previous command. The answer must be status 200 with a JavaScript content type. If the content type is `text/html`, nginx did not find the file and fell back to `index.html`, which is the cause of most blank pages.

Finally, ask the Perses proxy for data through the same origin the browser uses. This request reaches Prometheus through nginx and Perses, so it tests the whole path at once:

```sh
kubectl -n observability exec deploy/tester -- curl -s \
  'http://app.localtest.me:8081/proxy/globaldatasources/prometheus/api/v1/query?query=up'
```

The answer is JSON from Prometheus with a `status` field. A `success` status means the panel can get its data; an HTML page or a 404 means the proxy path or the nginx forwarding is wrong.

## Put the checks in order

Run the checks in this order, because each one rules out a whole group of causes: `npm ls --all` for the package tree, `npm run typecheck` for your code, the build output and the `grep` for the bundle, then the three requests for nginx and the proxy. When a check fails, fix that step and run it again before you go on.

You can now check an app at every step between the source and the browser. The lab asks you to use these checks on an app that does not build.

## Common pitfalls

> [!WARNING]
> - **Treating a finished build as a working page.** Vite does not check types, and it does not check that the packages fit together.
> - **Using `npm outdated` as a pass or fail check.** It exits with 1 whenever anything is behind, and with pinned versions that is normal.
> - **Testing only the page.** `index.html` can load while its JavaScript answers with HTML. Request the script itself.
> - **Skipping the proxy request.** A page can load and still show no data, because nginx or Perses forwards the request wrongly.

## Your mission: Align The Perses Package Versions

You can now install, build and serve the app, and read an npm peer dependency error. The graded lab gives you an app whose `package.json` mixes three releases, so `npm install` fails, and asks you to pin versions that fit Perses v0.54.0 and serve a working build.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-110-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-110-lab-010-01
astrona start ats-110-playground-010-01
```
