# Overview

This repository contains the scripts and metadata associated with **[add final version here + URL]**

## How to use this repository

You can [download][1] or clone the repository then run the scripts using the *pollinator-image-annotation.Rproj* file ([R][2] and [R Studio][3] are needed).

For cloning, run this in a terminal (git should be [installed][4]):

```
git clone https://github.com/valentinitnelav/pollinator-image-annotation.git
```

[1]: https://github.com/valentinitnelav/pollinator-image-annotation/archive/refs/heads/main.zip
[2]: https://www.r-project.org/
[3]: https://www.rstudio.com/products/rstudio/download/
[4]: https://git-scm.com/downloads


In the directory "./data-descriptor-scripts":

- `data_descriptor.r`- R script to get the descriptive stats reported in the manuscript.
- `histogram_n_img_by_hours.r` - R script to create Figure in Appendix Figure I. Frequency of images by hour of the day.
- `img_metadata_stats.r` - R script to compute descriptive stats about image metadata for Table 3.
- `insect_taxa_barplots.r` - R script to create the barplots with taxa level identification. The figures are saved in the directory "./figures".
- `time_stats.r` - R script to compute stats regarding the time step between consecutive images and session duration per plant-folder (target flower).

In the directory "./annotation-scripts" one finds R and Python scripts with examples regarding how to read the VGG Image Annotator (VIA) JSON files and how to convert them to data frames.

Metadata regarding the images and arthropod annotation is stored in the directory "./data"

## R packages & R session information

Information about the R session used was obtained with the command:
```r
sessionInfo()
```

```
R version 4.4.0 (2024-04-24)
Platform: x86_64-pc-linux-gnu
Running under: Ubuntu 22.04.4 LTS

Matrix products: default
BLAS:   /usr/lib/x86_64-linux-gnu/atlas/libblas.so.3.10.3 
LAPACK: /usr/lib/x86_64-linux-gnu/atlas/liblapack.so.3.10.3;  LAPACK version 3.10.0

locale:
 [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C               LC_TIME=en_GB.UTF-8        LC_COLLATE=en_US.UTF-8    
 [5] LC_MONETARY=en_GB.UTF-8    LC_MESSAGES=en_US.UTF-8    LC_PAPER=en_GB.UTF-8       LC_NAME=C                 
 [9] LC_ADDRESS=C               LC_TELEPHONE=C             LC_MEASUREMENT=en_GB.UTF-8 LC_IDENTIFICATION=C       

time zone: Europe/Berlin
tzcode source: system (glibc)

attached base packages:
[1] stats     graphics  grDevices utils     datasets  methods   base     

other attached packages:
[1] checkpoint_1.0.2  forcats_1.0.0     tidyr_1.3.1       scales_1.3.0      ggplot2_3.5.1     magrittr_2.0.3    data.table_1.15.4

loaded via a namespace (and not attached):
 [1] vctrs_0.6.5       knitr_1.46        cli_3.6.2         xfun_0.43         rlang_1.1.3       purrr_1.0.2       generics_0.1.3   
 [8] glue_1.7.0        colorspace_2.1-0  htmltools_0.5.8.1 fansi_1.0.6       rmarkdown_2.26    grid_4.4.0        munsell_0.5.1    
[15] evaluate_0.23     tibble_3.2.1      fastmap_1.1.1     lifecycle_1.0.4   compiler_4.4.0    dplyr_1.1.4       pkgconfig_2.0.3  
[22] rstudioapi_0.16.0 digest_0.6.35     R6_2.5.1          tidyselect_1.2.1  utf8_1.2.4        pillar_1.9.0      tools_4.4.0      
[29] withr_3.0.0       gtable_0.3.5 
```

### Use the R `checkpoint` package for reproducible research

**WARNING**: 

This was tested only when using RStudio and having a "project" for this repository (e.g. [Using RStudio Projects][rstudio_01], or [RStudio Projects and Working Directories: A Beginner’s Guide][rstudio_02]).

[rstudio_01]: https://support.posit.co/hc/en-us/articles/200526207-Using-RStudio-Projects
[rstudio_02]: https://www.r-bloggers.com/2020/01/rstudio-projects-and-working-directories-a-beginners-guide/

If you do not specify a project, running the `checkpoint` command below could cause it to scan all R files on your computer for `library()` and `require()` calls. This might result in a large number of packages being installed in the library associated with this repository.

```r
# First intall the R package `checkpoint`
install.packages("checkpoint")

library(checkpoint)
checkpoint(snapshot_date="2024-06-01", r_version="4.4.0", checkpoint_location = "~")
# Default location is "~", i.e. your home directory.

# For older versions of R, but not recommended due to possilbe package dependcy incompatibilities:
checkpoint(snapshot_date="2024-06-01", checkpoint_location = "~") 
```

## Example of annotation with VGG Image Annotator (VIA)

During the manual annotation process, we utilized the freely available, open-source [VGG Image Annotator (VIA)][1] to enclose any detected insect within a tightly-fitted bounding box and documented its taxonomic order. 

An online demo of the annotation tool can be found at [this link][2]. Below we present our workflow. Readers are encouraged to also consult the detailed 'User Guide' section of the [VGG Image Annotator (VIA)][1] for more instructions.

We annotated each "plant-folder" with its own JSON file created by the VIA application.

Once you open the via.html file (e.g. double click), the software runs directly in your browser and you should see an empty canvas like this:

![image](https://github.com/valentinitnelav/pollinator-image-annotation/assets/14074269/d839a2c2-d17f-4b72-bb16-b9798692ca9d)

For each plant folder, load the empty JSON template (see `./data/via_annotation_project_template.json`) with predefined attribute tables. 
In the via app, go to menu `Project` then select `Load`, like below:

![image](https://github.com/valentinitnelav/pollinator-image-annotation/assets/14074269/1097c159-e5e3-4530-941d-29f15bdd8433)

Then navigate to find the needed `json` file and open it.

Once the `json` template file is loaded, then we can add an entire folder of images to label/annotate. Go to menu `Project` and select `Add local files`, as below:

![image](https://github.com/valentinitnelav/pollinator-image-annotation/assets/14074269/4bf50919-1533-4adf-ae61-7e070b2e1c53)

Navigate to the folder containing the images you wish to annotate. In the pop-up window, select all the images from the folder by pressing `CTRL + A`. Click `Open` to load the images. Once loaded, the first image from the folder should be visible in the canvas.

Begin annotation by clicking on the initial corner of your desired bounding box and dragging to the opposite corner, aiming to encapsulate the insect snugly, including all extremities such as antennae, which may aid identification:

![image](https://github.com/valentinitnelav/pollinator-image-annotation/assets/14074269/cd5a78c9-123d-4800-a792-107e2deb3318)

Upon releasing the mouse, an attribute table may pop up; disregard this for the moment.

Ensure your bounding box is deselected by clicking elsewhere on the image. Once deselected, navigate to the next image using the right arrow key. Note: if the bounding box is selected, using the arrow keys will simply move the box rather than progress to the next image.

To save the *.json project file with you annotations:

![image](https://github.com/valentinitnelav/pollinator-image-annotation/assets/14074269/036ca99f-2b55-4046-8478-edc039191ab0)

Bear in mind that the JSON file is stored locally in your computer's default Downloads folder. Each time you save, a new JSON file is created, with the operating system adding an index to the file name for distinction; the most recent file corresponds to your latest work.

The software doesn't auto-save, so in case of potential crashes - although rare with VIA - make a habit of saving your work frequently.

### Extra notes:

The 'attribute table' below the image can be toggled on or off using the 'spacebar'. A list of keyboard shortcuts is available on the left side of the VIA app. Remember, 'region' refers to a 'box' in the image.

Each row in the attribute table corresponds to a box. If you need to delete boxes, select the box in the image and press 'd'. To delete all boxes, press 'a' and then 'd'.

Zooming in can be also achieved by hovering the mouse pointer over the image (not the page frame), holding 'CTRL', and scrolling the mouse. This is the same as zooming in on a webpage, but ensure the mouse is over the image. If the mouse hovers over the page frame, the entire page will zoom. To reset the zoom, press 'CTRL + 0'.

Existing attributes within our JSON template project file can be modified as needed. If there are missing orders, you can update the template by adding new option IDs to the 'order' dropdown attribute:

![image](https://github.com/valentinitnelav/pollinator-image-annotation/assets/14074269/944f3666-3e9a-4344-b745-5f481135de18)

See more details about defining attributes for your custom template at [Creating Annotations : VIA User Guide][3]

[1]: https://www.robots.ox.ac.uk/~vgg/software/via/
[2]: https://www.robots.ox.ac.uk/~vgg/software/via/via_demo.html
[3]: https://www.robots.ox.ac.uk/~vgg/software/via/docs/creating_annotations.html

