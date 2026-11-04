# When A Variable Or A Panel Stays Empty

An empty control or an empty panel has a short list of causes. This part is a checklist in the order that finds the cause fastest. For every item, the check tells you what to look at, and the fix follows.

## Start with the browser

Open the developer tools of the browser and load the page again. Two tabs matter: the console for errors, and the network for requests. A page that is blank and has an error in the console failed in its code. A page that is drawn but empty failed in the data.

## The variable has no options

The control is drawn, and the list is empty or says there are no options.

1. **The options request.** In the network tab, find the request that ends with `/api/v1/label/job/values`. If there is none, the plugin did not run. If it exists, check its status.
2. **Status 404 or 500 on the proxy path.** The proxy path is wrong or the datasource name does not exist. The path has the form `/proxy/globaldatasources/NAME/api/v1/label/job/values`. Compare NAME with the output of `curl` on `/api/v1/globaldatasources` through the same origin.
3. **Status 200 with an empty list.** Prometheus has no values for that label. Run the same path with `curl` and read the answer. A label that does not exist gives an empty list, not an error.
4. **No request at all.** The plugin kind in the definition is misspelled, or the plugin module is missing in the loader. The console shows a message that the plugin was not found.
5. **The control is not drawn.** `VariableList` is missing, or the variable has `display.hidden: true`.

## The variable has options, and the panel is empty

1. **The value in the query.** In the network tab, read the `query` parameter. If it still contains `$job`, nothing replaced the name. The usual cause is that the query is not inside the provider that holds the variable, or the name has a character other than letters, digits and underscore.
2. **A list with `=`.** If the query holds `(a|b)` after the operator `=`, no series matches. Use `=~`.
3. **The value is empty.** If "All" gives `job=~""`, the variable has no options yet, or the options were not loaded when the query ran. Check the options request first.
4. **The label name.** Prometheus label names are case-sensitive. `Job` and `job` are different labels.

## The panel is empty, and no variable is involved

1. **The status of the range query.** A `400` means the query text is wrong, and the body says why. A `502` or `503` from the proxy means Perses could not reach Prometheus.
2. **A query that returns no series for the range.** Run the query for a longer range, or run it as an instant query with `curl`. If the metric exists only for the last minute, a one-hour chart shows a short line.
3. **The panel has no height.** The chart is drawn at the size of its parent. A parent with height zero draws nothing, and the console has no error.
4. **The plugin kind.** `TimeSeriesChart` and `StatChart` must both be in the plugin loader, and both packages must be installed and built into the bundle.

## The page is blank

1. **The console error.** A missing provider has a message that names the hook, such as one saying that a context was not found. Add the provider the message names, outside the component that failed.
2. **The built file.** The page loads `index.html`, which loads one script from `assets/`. If the script gives a 404, the build did not finish or nginx serves an old folder. Run `ls` on the build folder in the pod.
3. **Wrong `base`.** If the app is served from a path that is not `/`, set `base` in `vite.config.ts`. This app is served from the root.

## Quick checks with curl

These three requests, run through the origin of the app, separate the app from the server:

```sh
curl -s http://app.localtest.me:8081/api/v1/globaldatasources
curl -s "http://app.localtest.me:8081/proxy/globaldatasources/prometheus/api/v1/label/job/values"
curl -s "http://app.localtest.me:8081/proxy/globaldatasources/prometheus/api/v1/query?query=up"
```

The first lists the datasources, the second returns the options, and the third runs an instant query. If all three work and the page is still empty, the fault is in the app. If one fails, fix that layer first.

Use the datasource name from the first answer in place of `prometheus` if it is different.

## Common pitfalls

> [!WARNING]
> - **Changing the app before reading the request.** The network tab shows in seconds which layer failed.
> - **Reading only the status.** The body of a 400 holds the Prometheus message.
> - **Testing through a different origin.** A direct call to the Perses port skips nginx. A fault in the nginx rule shows only when you test through the app origin.

## Your mission: Add A Job Variable And Time Controls

You can now define a list variable, show it, use it in queries, add time controls, and find why something stays empty. The graded lab gives you the app from the first module and asks for a `job` variable that filters both panels and a set of time controls with given defaults.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-110-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-110-lab-020-02
astrona start ats-110-playground-020-02
```
