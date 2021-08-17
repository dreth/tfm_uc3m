## Mortality tab

### Description

The mortality tab produces a time series plot with *week* in the x-axis and the specific mortality metric chosen in the y-axis. The metrics that can be selected are: Cumulative mortality rate, Cumulative relative mortality rate, Mortality improvement factor and Excess mortality.

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
      + *plotly*: Shows an interactive plot (an embedded HTML object)

+   *Selection of CCAA* to plot for (or aggregate for all of them).

    + **Options**:
      + *All CCAAs*: Aggregates all CCAAs' values
      + *Select CCAAs*: Allows for a selection of individual or multiple CCAAs. If multiple are selected, their values are aggregated.

+ *Selection of Age group* to plot for (or aggregate for all of them).

    + **Options**:
      + *All Age groups*: Aggregates all Age groups' values
      + *Select Age groups*: 

+ *Select Sex/Total* to plot for. If total is selected, it'll compute an aggregation of values for males and females.

    + **Options**:
      + Females
      + Males
      + Total

+ *Select week range* to plot for.

  + **Options**:
    + Slider from 1 to 52 with a selector for bottom and top bounds.

+ *Select year range* to plot for.

  + **Options**:
    + Depending on the metric the slider will have a bottom bound of 2015 for excess mortality, 2011 for cumulative improvement factor and 2010 for the remaining metrics. The top bound will always be the latest year in the data, usually the current year.

### Download controls

  + *Selection of image size* in pixels by pixels.

    + **Options** 
      + *Predefined*: will show a set of predefined plot sizes, all are squares.
      + *Custom*