## Mortality tab

### Description

The mortality tab produces a time series plot with *week* in the x-axis and the specific mortality metric chosen in the y-axis. The metrics that can be selected are: Cumulative mortality rate, Cumulative relative mortality rate, Mortality improvement factor and Excess mortality. The plot can be static (using [ggplot2](https://ggplot2.tidyverse.org/reference/ggplot.html)) or interactive (using [plotly](https://plotly.com/r/)).

### Controls

+  *Selection of metric* to plot.
    + **Options**:
      +  Cumulative mortality rate
      +  Cumulative relative mortality rate
      +  Mortality improvement factor
      +  Excess mortality

&nbsp;

+   *Selection of the plotting library* to be used.
    + **Options**:
      + *ggplot2*: Shows a static plot (an image)
      + *plotly*: Shows an interactive plot (an embedded HTML object)

&nbsp;

+   *Selection of CCAA* to plot for (or aggregate for all of them).
    + **Options**:
      + *All CCAAs*: Aggregates all CCAAs' values
      + *Select CCAAs*: Allows for a selection of individual or multiple CCAAs. If multiple are selected, their values are aggregated.

&nbsp;

+ *Selection of Age group* to plot for (or aggregate for all of them).
    + **Options**:
      + *All Age groups*: Aggregates all Age groups' values
      + *Select Age groups*: Allows for a selection of individual or multiple age groups. If multiple are selected, their values are aggregated.

&nbsp;

+ *Selection of Sex/Total* to plot for. If total is selected, it'll compute an aggregation of values for males and females.
    + **Options**:
      + Females
      + Males
      + Total

&nbsp;

+ *Selection of week range* to plot for.
  + **Options**:
    + Slider from 1 to 52 with a selector for bottom and top bounds.

&nbsp;

+ *Selection of year range* to plot for.
  + **Options**:
    + Depending on the metric the slider will have a bottom bound of 2015 for excess mortality, 2011 for cumulative improvement factor and 2010 for the remaining metrics. The top bound will always be the latest year in the data, usually the current year.

&nbsp;

+ *Generate plot button*: generates the plot, will notify with a red label when parameters have been changed. It has to be clicked to generate the plot whenever the paramaters have been changed.

### Download controls

+ *Selection of image size* in pixels by pixels.
  + **Options** 
    + *Predefined*: shows a set of predefined plot sizes, all are squares.
    + *Custom*: shows custom width and height selectors.

&nbsp;

+ *Selection of image dimension* whose output is determined by the previous field. 
  + **Options**:
    + If *predefined* is selected in the previous field the following dimensions are available (in pixels by pixels):
      + 200x200
      + 500x500
      + 800x800
      + 1200x1200
      + 2000x2000
    + If *custom* is selected, there will be a field for selection of width or height whose default value will be 500x500, but can be changed to any size. Both width and height are measured in pixels.

&nbsp;

+ *Selection of image format* depends on the options of [ggsave](https://ggplot2.tidyverse.org/reference/ggsave.html), the function used to output the images. Only those options that do not require an extra library installation are included.
  + **Options**:
    + .png
    + .jpeg
    + .pdf
    + .eps
    + .tex
    + .tiff
    + .bmp