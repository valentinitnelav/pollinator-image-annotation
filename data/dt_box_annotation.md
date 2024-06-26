# Metadata

## General Information

Metadata for the binary file file dt_box_annotation.rds which contains a tabular dataset metadata for each bounding box containing an insect in the annotated images.

It includes 35,194 observations (rows), each representing a bounding box associated with an insect.

### Data Format

This structure provides a detailed framework for the dataset, encompassing both taxonomic classifications and image-specific information.

The tabular dataset stored in the rds binary file is structured as a `data.table` in R, with the following 31 variables.

1. **date**: The date on which the image was captured.
2. **plant_folder**: Identifier of the plant folder / target flower.
3. **filename**: Name of the image file.
4. **id_box**: Unique identifier for each bounding box within an image.
5. **n_boxes**: Number of bounding boxes in the image.
6. **order**: Taxonomic order of the arthropod.
7. **conf_order**: Confidence level in identifying the order.
8. **suborder**: Taxonomic suborder of the arthropod.
9. **conf_suborder**: Confidence level in identifying the suborder.
10. **infraorder**: Taxonomic infraorder.
11. **conf_infraorder**: Confidence level in identifying the infraorder.
12. **superfamily**: Taxonomic superfamily.
13. **conf_superfamily**: Confidence level in identifying the superfamily.
14. **family**: Taxonomic family.
15. **conf_family**: Confidence level in identifying the family.
16. **clustergenera**: Cluster genera group.
17. **conf_clustergenera**: Confidence level in identifying the clustergenera.
18. **genus**: Taxonomic genus.
19. **conf_genus**: Confidence level in identifying the genus.
20. **morphospecies**: Morphospecies classification.
21. **conf_morphospecies**: Confidence level in identifying the morphospecies.
22. **species**: Taxonomic species.
23. **conf_species**: Confidence level in identifying the species.
24. **species_sex**: Sex of the species.
25. **conf_species_sex**: Confidence level in identifying the species sex.
26. **x**: X-coordinate of the bounding box (in pixels).
27. **y**: Y-coordinate of the bounding box (in pixels).
28. **width**: Width of the bounding box (in pixels).
29. **height**: Height of the bounding box (in pixels).
30. **plant_genus**: Genus of the plant / target flower.
31. **plant_epithet**: Specific epithet of the plant / target flower.


To have a look at structure of the data table object from R:

```r
library(data.table)

# Annotated bounding boxes (a row = a bounding box)
dt_box <- readRDS(file = "./data/dt_box_annotation.rds")
str(dt_box)
```

```
Classes ‘data.table’ and 'data.frame':	35194 obs. of  31 variables:
 $ date              : chr  "2021-07-06" "2021-07-06" "2021-07-06" "2021-07-06" ...
 $ plant_folder      : chr  "Centaurea-scabiosa-01" "Centaurea-scabiosa-01" "Centaurea-scabiosa-01" "Centaurea-scabiosa-01" ...
 $ filename          : chr  "IMG_0376.JPG" "IMG_0377.JPG" "IMG_0378.JPG" "IMG_0379.JPG" ...
 $ id_box            : chr  "1" "1" "1" "1" ...
 $ n_boxes           : chr  "1" "1" "1" "1" ...
 $ order             : chr  "coleoptera" "coleoptera" "coleoptera" "coleoptera" ...
 $ conf_order        : chr  "high" "high" "high" "high" ...
 $ suborder          : chr  "polyphaga" "polyphaga" "polyphaga" "polyphaga" ...
 $ conf_suborder     : chr  "high" "high" "high" "high" ...
 $ infraorder        : chr  NA NA NA NA ...
 $ conf_infraorder   : chr  NA NA NA NA ...
 $ superfamily       : chr  NA NA NA NA ...
 $ conf_superfamily  : chr  NA NA NA NA ...
 $ family            : chr  "chrysomelidae" "chrysomelidae" "chrysomelidae" "chrysomelidae" ...
 $ conf_family       : chr  "medium" "medium" "medium" "medium" ...
 $ clustergenera     : chr  NA NA NA NA ...
 $ conf_clustergenera: chr  NA NA NA NA ...
 $ genus             : chr  "cetonia" "cryptocephalus" "cryptocephalus" "cryptocephalus" ...
 $ conf_genus        : chr  "medium" "medium" "medium" "medium" ...
 $ morphospecies     : chr  NA NA NA NA ...
 $ conf_morphospecies: chr  NA NA NA NA ...
 $ species           : chr  NA NA NA NA ...
 $ conf_species      : chr  NA NA NA NA ...
 $ species_sex       : chr  NA NA NA NA ...
 $ conf_species_sex  : chr  NA NA NA NA ...
 $ x                 : chr  "1039" "1046" "1048" "1045" ...
 $ y                 : chr  "886" "864" "894" "890" ...
 $ width             : chr  "167" "150" "141" "139" ...
 $ height            : chr  "180" "210" "176" "183" ...
 $ plant_genus       : chr  "centaurea" "centaurea" "centaurea" "centaurea" ...
 $ plant_epithet     : chr  "scabiosa" "scabiosa" "scabiosa" "scabiosa" ...
 - attr(*, ".internal.selfref")=<externalptr> 
 - attr(*, "sorted")= chr "date"
 - attr(*, "index")= int(0) 
```