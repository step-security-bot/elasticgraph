[`equalToAnyOf`]({% link query-api/filtering/equality.md %})
: Matches records where the field value is equal to any of the provided values.
  This works just like an `IN` operator in SQL.

  Will be ignored when `null` is passed.
  When an empty list is passed, will cause this part of the filter to match no documents.
  When `null` is passed in the list, will match records where the field value is `null`.
