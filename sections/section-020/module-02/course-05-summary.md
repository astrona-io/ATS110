# Summary

A variable is a named value held by `VariableProvider`. A text variable holds one value. A list variable offers options, and a variable plugin decides where they come from: `PrometheusLabelValuesVariable` reads the values of a label, `PrometheusLabelNamesVariable` the label names, and `PrometheusPromQLVariable` the result of a query. A query that contains `$name` or `${name}` is rewritten before it is sent, so every panel that mentions the name runs again when the value changes.

One value is written as it is. Several values are written as `(a|b)`, which only a regular expression match understands, so use `=~` in the selector. A format after the name, such as `${name:csv}`, changes the form. The "All" choice is the string `$__all`, which becomes every option, or the `customAllValue` if the definition has one. The names `$__interval`, `$__interval_ms` and `$__rate_interval` are built in, and depend on the range and the panel width.

The time range is either relative (`pastDuration`) or absolute (`start` and `end`, as `Date` objects). `useTimeRange` gives the range, the resolved start and end, and the setters. `TimeRangeControls` draws the selector, the refresh controls and the time zone choice, and asks the app to hold the time zone. When something stays empty, read the requests in the network tab first. The key facts to remember are these:

- Pass definitions with `initialVariableDefinitions`, and define the array outside the component.
- Place `VariableList` inside both `VariableProvider` and `DatasourceStoreProvider`.
- Use single quotes around a query that contains `${name}`.
- Use `=~` for a variable that allows several values.
- Check the options request before changing code.

<!-- astrona:playground:destroy -->
