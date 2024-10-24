---
layout: markdown
title: "ElasticGraph Query API: Comparison Filtering"
permalink: /query-api/filtering/comparison/
subpage_title: "Comparison Filtering"
---

ElasticGraph offers a standard set of comparison filter predicates:

{% include filtering_predicate_definitions/comparison.md %}

{% highlight graphql %}
{{ site.data.music_queries.filtering.FindArtistsFormedIn90s }}
{% endhighlight %}
