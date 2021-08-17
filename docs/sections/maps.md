## Maps tab

### Description

The maps tab produces a choropleth map of Spain by CCAA, where each CCAA is coloured according to the metric selected. The map can be an interactive embedded object (using [leaflet](https://rstudio.github.io/leaflet/)) or a static image (using [ggplot2](https://ggplot2.tidyverse.org/reference/ggplot.html)).

### Controls


+  *Selection of metric* to plot.

    + **Options**:
      +  Cumulative mortality rate
      +  Cumulative relative mortality rate
      +  Mortality improvement factor
      +  Excess mortality

+   *Selection of the plotting library* to be used.
    
    + **Options**:
      + *ggplot2*: Shows a static plot (an image)
      + *leaflet*: Shows an interactive plot (an embedded HTML object)

+ *Selection of Sex/Total* to plot for. If total is selected, it'll compute an aggregation of values for males and females.

    + **Options**:
      + Females
      + Males
      + Total

+ *Selection of the week* to generate the map for for.

    + **Options**:
      + The selector will allow a selection of an individual week (usually anywhere between 1 to 52), however, for ongoing years, the selection range may have a lower upper bound.

+ *Selection of the year* to generate the map for for.

    + **Options**:
      + The selector will include years starting from 2011 and ending at the current year.

