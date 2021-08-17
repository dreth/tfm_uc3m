## Life expectancy tab

### Description

The life expectancy tab produces either a time series of life expectancy (either at birth or for a selected age group). The time series is based on weekly life tables, therefore it's also possible to individually generate a life table for any week of the available years. The plot (if life expectancy time series is selected) can be static (using [ggplot2](https://ggplot2.tidyverse.org/reference/ggplot.html)) or interactive (using [plotly](https://plotly.com/r/)).

### Controls

+ The first selector allows *selecting between a life expectancy time series plot or a life table*.
    
    + **Options**:
      + Life expectancy time series
      + Life table
#### Plotting controls (Life expectancy time series)

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
      + *Select Age groups*: Allows for a selection of an individual age group to compute its life expectancy time series for.

+ *Selection of Sex/Total* to plot for. If total is selected, it'll compute an aggregation of values for males and females.

    + **Options**:
      + Females
      + Males
      + Total

+ *Selection of week range* to plot for.

  + **Options**:
    + Slider from 1 to 52 with a selector for bottom and top bounds.

+ *Selection of year range* to plot for.

  + **Options**:
    + Depending on the metric the slider will have a bottom bound of 2015 for excess mortality, 2011 for cumulative improvement factor and 2010 for the remaining metrics. The top bound will always be the latest year in the data, usually the current year.

+ *Generate plot button*: generates the plot, will notify with a red label when parameters have been changed. It has to be clicked to generate the plot whenever the paramaters have been changed.

#### Table controls (Life table)

+   *Selection of CCAA* to plot for (or aggregate for all of them).

    + **Options**:
      + *All CCAAs*: Aggregates all CCAAs' values
      + *Select CCAAs*: Allows for a selection of individual or multiple CCAAs. If multiple are selected, their values are aggregated.

+ *Selection of the week* to compute the life table for.

    + **Options**:
      + The selector will allow a selection of an individual week (usually anywhere between 1 to 52), however, for ongoing years, the selection range may have a lower upper bound.

+ *Selection of the year* to compute the life table for.

    + **Options**:
      + The selector will include years starting from 2011 and ending at the current year.

+ *Generate table button*: generates the table, will notify with a red label when parameters have been changed. It has to be clicked to generate the table whenever the paramaters have been changed.

### Download controls

#### Plot download controls (Life expectancy time series)

+ *Selection of image size* in pixels by pixels.

  + **Options** 
    + *Predefined*: shows a set of predefined plot sizes, all are squares.
    + *Custom*: shows custom width and height selectors.

+ *Selection of image dimension* whose output is determined by the previous field. 

  + **Options**:
    + If *predefined* is selected in the previous field the following dimensions are available (in pixels by pixels):
      + 200x200
      + 500x500
      + 800x800
      + 1200x1200
      + 2000x2000
    + If *custom* is selected, there will be a field for selection of width or height whose default value will be 500x500, but can be changed to any size. Both width and height are measured in pixels.

+ *Selection of image format* depends on the options of [ggsave](https://ggplot2.tidyverse.org/reference/ggsave.html), the function used to output the images. Only those options that do not require an extra library installation are included.

  + **Options**:
    + .png
    + .jpeg
    + .pdf
    + .eps
    + .tex
    + .tiff
    + .bmp

#### Table download controls (Life table)

There will only be a download button when a *life table* is generated. The file is outputted in *CSV* format.