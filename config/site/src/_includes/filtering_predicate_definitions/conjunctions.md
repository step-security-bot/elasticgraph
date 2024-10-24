[`allOf`]({% link query-api/filtering/conjunctions.md %})
: Matches records where all of the provided sub-filters evaluate to true.
  This works just like an `AND` operator in SQL.

  Note: multiple filters are automatically ANDed together. This is only needed when you have multiple
  filters that can't be provided on a single filter input because of collisions between key names.
  For example, if you want to provide multiple `anySatisfy: ...` filters, you could do `allOf: [{anySatisfy: ...}, {anySatisfy: ...}]`.

  Will be ignored when `null` or an empty list is passed.

[`anyOf`]({% link query-api/filtering/conjunctions.md %})
: Matches records where any of the provided sub-filters evaluate to true.
  This works just like an `OR` operator in SQL.

  Will be ignored when `null` is passed. When an empty list is passed, will
  cause this part of the filter to match no documents.
