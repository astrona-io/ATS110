# The Time Range In Depth

The first module put one `TimeRangeProvider` around the panels and set the initial values with `useState`. This part covers the two forms a time range can take, the controls that Perses ships, and the other values that depend on the range.

## Two forms of range

The type `TimeRangeValue` from `@perses-dev/spec` is one of two shapes:

```ts
// Relative: the last six hours, up to now
{ pastDuration: '6h' }

// Relative, ending at a fixed moment
{ pastDuration: '1h', end: new Date('2026-01-15T10:00:00Z') }

// Absolute: a fixed start and end
{ start: new Date('2026-01-15T08:00:00Z'), end: new Date('2026-01-15T10:00:00Z') }
```

A relative range moves with the clock. Each refresh computes a new start and end from "now". An absolute range does not move, so refreshing it gives the same window again. The functions `isRelativeTimeRange` and `isAbsoluteTimeRange` from `@perses-dev/spec` tell the two apart.

The durations are strings with a number and a unit, such as `30s`, `5m`, `1h`, `1d` and `1w`.

## What `useTimeRange` returns

Any component inside `TimeRangeProvider` can call `useTimeRange` from `@perses-dev/plugin-system`. It returns an object with these fields:

| Field | Meaning |
| --- | --- |
| `timeRange` | The value you gave the provider, relative or absolute |
| `absoluteTimeRange` | The same range as a start and an end, resolved against "now" |
| `setTimeRange` | Changes the range |
| `refresh` | Asks every query to run again |
| `refreshInterval` | The automatic refresh interval, if set |
| `refreshIntervalInMs` | The same interval in milliseconds |
| `setRefreshInterval` | Changes the interval |

A small component that shows the resolved range and moves it to the last fifteen minutes looks like this:

```tsx
import { useTimeRange } from '@perses-dev/plugin-system';

function RangeInfo(): ReactElement {
  const { absoluteTimeRange, setTimeRange } = useTimeRange();
  return (
    <div>
      <span>{absoluteTimeRange.start.toISOString()} to {absoluteTimeRange.end.toISOString()}</span>
      <button onClick={() => setTimeRange({ pastDuration: '15m' })}>Last 15 minutes</button>
    </div>
  );
}
```

`setTimeRange` calls the function you passed to the provider. The state lives in your component, so you can also store it somewhere else, for example in the address of the page.

## The ready-made controls

`TimeRangeControls` is exported by `@perses-dev/plugin-system`. It draws the range selector, a custom range picker, zoom buttons, the refresh button, the refresh interval and a time zone selector, all in one row. It reads and writes the provider, so it needs no state of its own, except the time zone, which it asks you to hold:

```tsx
const [timeZone, setTimeZone] = useState<string>('local');

<TimeRangeControls timeZone={timeZone} onTimeZoneChange={(option) => setTimeZone(option.value)} />
```

Its optional properties switch parts off: `showTimeRangeSelector`, `showCustomTimeRange`, `showZoomButtons`, `showRefreshButton` and `showRefreshInterval`. Set `showRefreshInterval={false}` for a page that must not poll. The property `timePresets` replaces the list of relative choices with your own, as an array of `TimeOption` values from `@perses-dev/components`.

The time zone is only a display setting. It changes how dates are written on the page and in chart axes. The queries are the same in every time zone, because they are sent as moments in time.

## Refresh

Two things make queries run again: the refresh button, which calls `refresh`, and the refresh interval, which calls it on a timer. When the range is relative, each run uses the new "now". The interval is a `DurationString`, so `'30s'` runs the queries every thirty seconds.

A short interval on many panels is many requests. Each panel sends one request for each query. A refresh interval of `5s` on a page of ten panels with two queries each is four requests per second to Prometheus for every open browser tab.

## The step

A range query asks Prometheus for points at a regular distance, called the **step**. A plugin computes it from the range and the width of the panel. The hook `useSuggestedStepMs` from `@perses-dev/plugin-system` returns this suggestion in milliseconds, and the function `getSuggestedStepMs` in `@perses-dev/spec` makes the same computation from a range and a width.

The step is also what `$__interval` is set to. A wider range gives a longer step, so a one-week chart does not request ten thousand points. The Prometheus query plugin has a minimum step field in its spec, `minStep`, for queries where the scrape interval is long and a shorter step only repeats values.

## A range from outside

Many pages store the range in the address, so that a link shows the same window. The provider makes this easy, because the state is yours. Read the values at start, pass them to `useState`, and write them back inside the function you give as `setTimeRange`. The only rule is that absolute ranges must hold `Date` objects, not strings.

## Try it

1. Add `TimeRangeControls` to the app and rebuild. Change the range to the last five minutes and the refresh interval to ten seconds.
2. Open the network tab of the browser and look at the `start`, `end` and `step` parameters of the range query. Compare the step for five minutes and for six hours.
3. Add the `RangeInfo` component above the panels. Click the button and watch both panels change.

## Common pitfalls

> [!WARNING]
> - **Passing ISO strings in an absolute range.** The fields are `Date` objects.
> - **Holding the time zone in the wrong place.** `TimeRangeControls` asks for it as a property because the time range provider does not store it.
> - **Setting a very short refresh interval.** Every panel and every viewer multiplies the load on the datasource.
> - **Using `[5m]` inside `rate()` on a long range.** The window can be shorter than the step. Use `$__rate_interval`.
