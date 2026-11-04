# When A Dashboard Does Not Render

A saved dashboard adds new places to fail: the document, the providers and the datasource lookup. This part is a checklist in the order that finds the cause fastest.

## The page shows an error message

The app printed the status of the dashboard request.

1. **A 404.** The project or the dashboard name is wrong, or the path is. The path is `/api/v1/projects/<project>/dashboards/<name>`.
2. **A 401 or 403.** The server asks for a login. This course's Perses allows anonymous reads. A server that does not needs the page to send a token, which this module does not cover.
3. **A network error.** nginx does not forward `/api/`, or the Perses pod is down. Test the same path with `curl` from the `tester` pod.

## The page is blank

1. **The console.** A message that no context was found names the missing provider. `Dashboard` needs `DashboardProvider`, and panels need the datasource store, the variable provider and the time range provider.
2. **The state.** If the page shows nothing and not even the loading message, the component above the providers failed to render. The console has the error.
3. **An empty dashboard.** If the document has no `layouts`, the page shows the empty state.

## The groups are drawn, the panels show errors

The red box on a panel has a message. Common ones:

1. **No datasource found.** The store searched the dashboard, the project and the global list, and found nothing for the selector. List the project datasources and the global datasources, and compare the name and the kind with the query's `datasource`.
2. **The plugin is missing.** The panel or query plugin is not in the plugin loader. The message names the plugin kind.
3. **A request error.** Read the status of the request in the network tab. A 404 on a path that begins with `/proxy/projects/` means the project datasource name does not exist or the nginx rule does not forward `/proxy/`.

## The panels are drawn, and empty

1. **The range.** A saved duration of `5m` on a metric that is scraped every minute gives a few points. Check `spec.duration`.
2. **A variable in a query.** If the query contains `$name`, the variable must exist in `spec.variables`, or be defined in the page. With no definition, the name stays in the text and the query matches nothing.
3. **The datasource.** It exists but points at a server with no data for that query.

## The panels are drawn, but the time range controls do nothing

The controls change the range in `TimeRangeProvider`. If the page does not render `TimeRangeControls`, nothing changes it. A dashboard that is shown without controls keeps the saved duration for the whole visit.

## A quick set of checks

Run these through the app origin from the `tester` pod, to separate the app from the server:

```sh
kubectl -n observability exec deploy/tester -- curl -s http://app.localtest.me:8081/api/v1/projects/inventory/dashboards/overview
kubectl -n observability exec deploy/tester -- curl -s http://app.localtest.me:8081/api/v1/projects/inventory/datasources
kubectl -n observability exec deploy/tester -- curl -s \
  "http://app.localtest.me:8081/proxy/projects/inventory/datasources/inventory-prometheus/api/v1/query?query=up"
```

The first returns the document, the second the datasources, and the third runs a query. If all three work and the page still fails, the fault is in the app.

## Common pitfalls

> [!WARNING]
> - **Reading only the first line of the console error.** The line that names the context or the plugin is usually below it.
> - **Comparing only the datasource name.** The kind must match as well.
> - **Testing against the Perses port.** That skips nginx.

## Your mission: Render A Saved Dashboard With A Project Datasource

You can now read a saved dashboard, render it, and make the `DatasourceApi` find a project datasource. The graded lab gives you the app from the first module, with two panels written into its code, and asks you to replace them with the saved dashboard `overview`, whose panels use the project datasource `inventory-prometheus`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-110-playground-020-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS110.git -c sections/section-020/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-110-lab-020-03
astrona start ats-110-playground-020-03
```
