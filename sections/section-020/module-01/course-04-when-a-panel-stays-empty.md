# When A Panel Stays Empty

An embedded panel can fail in four places: in the browser code, at the origin where nginx forwards requests, in the Perses proxy, and in Prometheus. The symptom is often the same, a panel with no data, so this part gives a way to find the place by looking at requests instead of guessing.

## Find the failing layer

Follow one query from the browser to the datasource. Each layer answers a question:

| Layer | Question | How to check |
| --- | --- | --- |
| Browser | Was a request sent? | Network tab of the developer tools |
| nginx | Did the request reach Perses? | The status of the request: 404 from nginx means no rule matched |
| Perses | Does the datasource exist, and is it reachable? | `/api/v1/globaldatasources`, then the proxy path |
| Prometheus | Does the query return series? | The same query as an instant query through the proxy |

Check them from the outside in. If a layer is fine, the fault is in a later one.

## Read the request

Open the network tab, reload, and find the request whose path starts with `/proxy/`. Three parts of it matter.

The path has the form `/proxy/globaldatasources/NAME/api/v1/query_range`. NAME must be a global datasource that exists. A path with the wrong name gets a 404 from Perses with a message from the proxy.

The query parameters are `query`, `start`, `end` and `step`. Copy `query`: it is the PromQL that was sent. If it is not what you meant, the fault is in the panel definition.

The status and the body. A `200` with `"result":[]` means the query ran and found nothing. A `400` has the Prometheus message in the body. A `502` means Perses could not reach Prometheus.

## Test the same path without the browser

From a pod in the cluster, call the same path through the app origin. The `tester` pod in the namespace `observability` has `curl`:

```sh
kubectl -n observability exec deploy/tester -- curl -s \
  "http://app.localtest.me:8081/proxy/globaldatasources/prometheus/api/v1/query?query=up"
```

The answer is JSON with `"status":"success"` and a `result` list. This confirms nginx, Perses and Prometheus in one request. If it works and the page is still empty, the fault is in the app code.

## Causes that look the same

1. **The datasource name.** The default datasource is used only when the plugin spec has no `datasource` field. If you wrote a name, it must exist.
2. **The nginx rule.** The app origin must forward `/api/` and `/proxy/`. If only `/api/` is forwarded, the datasource list loads and every query fails.
3. **A datasource without a default.** If no datasource has `spec.default: true`, the app has none to pick when the plugin names none.
4. **The panel has no height.** The chart fills its parent. A parent of zero height draws nothing and logs nothing.
5. **A plugin missing from the loader.** The console shows that the plugin could not be found, and the panel shows an error box.
6. **A time range with no data.** A metric that started a minute ago gives a short line on a one-hour chart. A stat panel with `last-number` gives the last value in the range, and no value if the range has none.

## Try it

1. Open the network tab and find the proxy request of the "Targets up" panel. Copy the `query` value.
2. Change the datasource name in the `DatasourceApi` to one that does not exist, rebuild, and read the status in the network tab. Put it back.
3. Set the height of the panel's parent to `0` and rebuild. The panel disappears without an error. Put it back.

## Common pitfalls

> [!WARNING]
> - **Changing the code before reading the request.** The status and the body usually name the cause.
> - **Testing against the Perses port instead of the app origin.** That skips nginx, so a broken nginx rule goes unnoticed.
> - **Treating `"result":[]` as an error.** The query ran. The selector or the range matched no series.

## Your mission: Embed Two Panels That Query Through Perses

You can now write a `DatasourceApi` for the Perses server and place several panels with their own queries. The graded lab starts from the guide's app with its hard-coded datasource, and asks for a page with two given panels that get their data from the Perses datasource through the proxy.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-110-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-110-lab-020-01
astrona start ats-110-playground-020-01
```
