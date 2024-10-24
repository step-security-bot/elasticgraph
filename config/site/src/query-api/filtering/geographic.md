---
layout: markdown
title: "ElasticGraph Query API: Geographic Filtering"
permalink: /query-api/filtering/geographic/
subpage_title: "Geographic Filtering"
---

The `GeoLocation` type supports a special predicate:

{% include filtering_predicate_definitions/near.md %}

{% highlight graphql %}
{{ site.data.music_queries.filtering.FindSeattleVenues }}
{% endhighlight %}
