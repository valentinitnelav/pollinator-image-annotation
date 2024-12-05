# Script to get descriptive stats & tables reported in the manuscript and appendices

library(data.table)
library(magrittr)

# Read data ---------------------------------------------------------------

# Annotation data - bounding box info 
dt <- readRDS(file = "./data/dt_box_annotation.rds")

dt[, .N, keyby = order]
#           order     N
# 1:      araneae  1158
# 2:   coleoptera  3254
# 3:      diptera  5963
# 4:    hemiptera   812
# 5:  hymenoptera 20987
# 6:  lepidoptera    44
# 7:        no_id    11
# 8: thysanoptera  2965

# Image metadata - all images parsed
dt_img_anno <- readRDS(file = "./data/dt_img_exif_metadata.rds")
nrow(dt_img_anno) # 460056


# General stats -----------------------------------------------------------

# Create a unique key for each image
dt[, img_path := paste(date, plant_folder, filename, sep = "/")]
dt_img_anno[, img_path := paste(date, plant_folder, filename, sep = "/")]

# Dates for the annotated plant-folders
field_date <- dt[['date']] %>% unique %>% sort
range(field_date)
# "2021-07-06" "2021-09-16" # July - September

# How many dates are within the annotated folder?
length(field_date) # 18

# How many annotated images per plant?
dt[, plant := paste(plant_genus, plant_epithet, sep = "_")]
dt[, .(n_box = .N, n_img = uniqueN(img_path)), keyby = plant]

# How many annotated folder (complete or incomplete annotation)
dt[, .N, keyby = .(date, plant_folder)] # 213 plant-folders annotated

# Number of annotated images and boxes
dt[, .(n_img = uniqueN(img_path))] # 33502 images
nrow(dt) #  35194 boxes

# How many images per counts of bounding boxes?

# To get the correct number of images with 1, 2, 3 & 4 boxes, use n_boxes and
# not id_box. If you use id_box, you inflate the numbers because an image that
# has 4 boxes, also has an id_box = 3 and it gets counted in as well, when it
# should not be because it has 4 boxes, so it gets counted 2 times.
dt[, .(n_rows = .N, n_img = uniqueN(img_path)), keyby = n_boxes][
  , img_prc := round(n_img/sum(n_img) *100, 2)][order(-img_prc)]
#    n_boxes n_rows n_img  img_prc
# 1:       1  31901 31901    95.22
# 2:       2   3004  1505     4.49
# 3:       3    285    95     0.28
# 4:       4      4     1     0.00
# 31901 + 3004 + 285 + 4 = 35194, which is exactly nr rows in dt
# 31901 + 1505 + 95 + 1 = 33502, which is exactly number of unique images in dt (see above)


# How many images did we navigate through?
all(dt[["img_path"]] %in% dt_img_anno[["img_path"]]) # TRUE - expect TRUE
nrow(dt_img_anno) # 460056 images within the annotated folders
dt[, .(n_img = uniqueN(img_path))] # 33502 unique images
n_img_anno_prc <- dt[, .(n_img = uniqueN(img_path))] / nrow(dt_img_anno) * 100
round(n_img_anno_prc, 2) # 7.28%
# How many then lack insects?
100 - round(n_img_anno_prc, 2) # 92.72%



# Appendix Tab. I ---------------------------------------------------------

# List of sampled plant species and number of annotated images.
# Plant species that we sampled, number of sampled hours and number of annotated images.

# Update the dt_img_anno with the plant name. First create a table with unique
# entries for date and plant_folder.
dt_plant <- unique(dt[,.(date, plant_folder, plant)], by = c("date", "plant_folder"))
dt_img_anno <- merge(x = dt_img_anno, 
                     y = dt_plant,
                     by = c('date', 'plant_folder'),
                     all.x = TRUE)

# Get a table of unique annotated images
dt_img_unq <- dt[, .(img_path = unique(img_path), annotated = 1L)]
dt_img_anno2 <- merge(dt_img_anno, dt_img_unq, by = 'img_path', all.x = TRUE)
dt_img_anno2[, annotated := ifelse(is.na(annotated), 0, annotated)]

dt_img_anno2[, date_plant_folder := paste(date, plant_folder, sep = "_")]
tbl_spp_2 <- dt_img_anno2[, .(n_folders = uniqueN(date_plant_folder),
                              n_img_total = uniqueN(img_path), 
                              n_img_with_insect = sum(annotated)), 
                          keyby = plant]
tbl_spp_2[, percent_img_w_insect := round(n_img_with_insect/n_img_total*100, 2)]

tbl_spp_2_sum <- tbl_spp_2[, .(
  plant = "TOTAL",
  n_folders = sum(n_folders), 
  n_img_total = sum(n_img_total), 
  n_img_with_insect = sum(n_img_with_insect), 
  percent_img_w_insect = round(sum(n_img_with_insect)/sum(n_img_total)*100,2)
)]

tbl_spp_2_final <- rbindlist(list(tbl_spp_2, tbl_spp_2_sum), fill = TRUE)

# Force , as thousand separator so that is passed to the CVS file
tbl_spp_2_final[, n_img_total := format(n_img_total, big.mark = ",", scientific = FALSE)]
tbl_spp_2_final[, n_img_with_insect := format(n_img_with_insect, big.mark = ",", scientific = FALSE)]

# Rename columns with final names
setnames(tbl_spp_2_final, 
         new = c("Plant", "Nr. folders", "Nr. img.", "Nr. img. w. insect", "% img w. insect"))

# Prepare the species names. Capitalise 1st letter and replace _ with space.
tbl_spp_2_final[, Plant := tools::toTitleCase(Plant)]
tbl_spp_2_final[, Plant := gsub("_", " ", Plant)]


write.csv(tbl_spp_2_final, 
          file = './data/cache/Appendix_Table_plant_Nimg.csv',
          row.names = TRUE)

# Counts & percentages Hymenoptera -----------------------------------------------------

# N. instances (boxes) in order Hymenoptera
n_ord <- dt[order == "hymenoptera", .N]
n_ord # 20987

# N. instances identified to family
n_fam <- dt[order == "hymenoptera" & !is.na(family), .N]
n_fam # 18849
round(n_fam / n_ord * 100, 2) # 89.81%

# N. instances not identified to family
n_no_fam <- dt[order == "hymenoptera" & is.na(family), .N] 
n_no_fam # 2138
round(n_no_fam / n_ord * 100, 2) # 10.19%

# Of the 2,138 bounding boxes with insect instances that could be
# identified to order Hymenoptera but not further identified to family:
# 397 were outside the region of interest, 
# 11  were obscured, 
# 76  were too blurry, and 
# 1,655 were tiny wasps.
397 + 11 + 76 + 1654 # = expect 2138 as in n_no_fam
round(397/n_no_fam * 100, 2)  # 18.57%
round(11/n_no_fam * 100, 2)   #  0.51%
round(1654/n_no_fam * 100, 2) # 77.36%


# N. instances - table by family, including unidentified
dt_family <- dt[order == "hymenoptera", .(n_box = .N), keyby = family][, prc := round(n_box/sum(n_box) *100, 2)][]
dt_family
#           family n_box   prc
#           <char> <int> <num>
#  1:         <NA>  2138 10.19
#  2:   andrenidae   608  2.90
#  3:       apidae  8485 40.43
#  4:   colletidae   404  1.93
#  5:    cynipidae   390  1.86
#  6:   formicidae  2426 11.56
#  7:   halictidae  6153 29.32
#  8: megachilidae   195  0.93
#  9:   melittidae   181  0.86
# 10:   pompilidae     5  0.02
# 11:     vespidae     2  0.01

# N. instances - table by genus, including unidentified
dt_genus <- dt[order == "hymenoptera", .(n_box = .N), keyby = .(family, genus)][, prc := round(n_box/sum(n_box) *100, 2)][]
dt_genus
#           family        genus n_box   prc
#           <char>       <char> <int> <num>
#  1:         <NA>         <NA>  2138 10.19
#  2:   andrenidae         <NA>   355  1.69
#  3:   andrenidae      andrena   253  1.21
#  4:       apidae         apis  3307 15.76
#  5:       apidae       bombus  5178 24.67
#  6:   colletidae     colletes     2  0.01
#  7:   colletidae      hylaeus   402  1.92
#  8:    cynipidae         <NA>   390  1.86
#  9:   formicidae         <NA>  2426 11.56
# 10:   halictidae         <NA>  2092  9.97
# 11:   halictidae     halictus  2959 14.10
# 12:   halictidae lasioglossum  1102  5.25
# 13: megachilidae         <NA>    28  0.13
# 14: megachilidae    anthidium    13  0.06
# 15: megachilidae    megachile   150  0.71
# 16: megachilidae        osmia     4  0.02
# 17:   melittidae     dasypoda     3  0.01
# 18:   melittidae     macropis   178  0.85
# 19:   pompilidae     episyron     5  0.02
# 20:     vespidae         <NA>     2  0.01

# N. instances in family Apidae, genus Bombus & morphospecies
dt[family == "apidae" & !is.na(morphospecies), .N] # 5063

# N. instances of non pollinating Hymenoptera families
# Unlikely to be pollinators (families Cynipidae, Formicidae, Vespidae)
n_fam_non_poll <- dt[family %in% c("cynipidae", "formicidae", "vespidae"), .N]
n_fam_non_poll # 2818
round(n_fam_non_poll / n_fam * 100, 2) # 14.95%

# N. instances of pollinating Hymenoptera families
n_poll_fam <- n_fam - n_fam_non_poll
n_poll_fam # 16031
round(n_poll_fam / n_ord * 100, 2) # 76.39%

# N. instances identified to genus
n_genus <- dt[order == "hymenoptera" & !is.na(genus), .N]
n_genus # 13556
round(n_genus / n_fam * 100, 2) # 71.92% relative to all families
round(n_genus / n_poll_fam * 100, 2) # 84.56% relative to only pollinating families

# N. instances identified to species
n_sp <- dt[order == "hymenoptera" & !is.na(species), .N]
n_sp # 4064
round(n_sp / n_ord * 100, 2) # 19.36 relative to all Hymenoptera order
round(n_sp / n_fam * 100, 2) # 21.56% relative to all Hymenoptera families
round(n_sp / n_poll_fam * 100, 2) # 25.35% relative to only pollinating Hymenoptera families

# N. instances not identified to genus:
# - from all families, including non pollinating families
dt[order == "hymenoptera" & is.na(genus), .N] # 7431 
# - excluding non pollinators / Only from pollinating Hymenoptera families
n_no_genus_poll <- dt[order == "hymenoptera"][!is.na(family)][!(family %in% c("cynipidae", "formicidae", "vespidae"))][is.na(genus), .N]
n_no_genus_poll # 2475
2818 + 2475 # (no genus because non-pollinator + no genus of pollinators) = 5293 no genus info across all Hymenoptera instances
5293 + 13556 # 18849 - all Hymenoptera families

# From those with no genus info of pollinating families:
# 693 outside ROI, 171 obscured, 1611 blurry
693 + 171 + 1611 # expect 2475
round(693/n_no_genus_poll * 100, 2) #  28.00%
round(171/n_no_genus_poll * 100, 2) #   6.91%
round(1611/n_no_genus_poll * 100, 2) # 65.09%


# Counts & percentages Diptera -----------------------------------------------------

# N. instances (boxes) in order Hymenoptera
n_ord <- dt[order == "diptera", .N]
n_ord # 5963

# N. instances identified to family
n_fam <- dt[order == "diptera" & !is.na(family), .N]
n_fam # 3066
round(n_fam / n_ord * 100, 2) # 51.42%

# N. instances not identified to family
n_no_fam <- dt[order == "diptera" & is.na(family), .N] 
n_no_fam # 2897
round(n_no_fam / n_ord * 100, 2) # 48.58%

# N. instances - table by family, including unidentified
dt_family <- dt[order == "diptera", .(n_box = .N), keyby = family][, prc := round(n_box/sum(n_box) *100, 2)][]
dt_family
#                      family n_box   prc
# 1:                     <NA>  2897 48.58
# 2:             anthomyiidae    17  0.29
# 3:   calliphoridae/muscidae   184  3.09
# 4:              chyromyidae    57  0.96
# 5: sarcophagidae/tachinidae    15  0.25
# 6:                syrphidae  2761 46.30
# 7:               tachinidae    32  0.54

# N. instances not identified to genus
n_genus <- dt[order == "diptera" & !is.na(genus), .N]
n_genus # 1561
round(n_genus / n_ord * 100, 2) # 26.18%

# N. instances not identified to species
n_sp <- dt[order == "diptera" & !is.na(species), .N]
n_sp # 906
round(n_sp / n_ord * 100, 2) # 15.19%

# N. instances not identified to Syrphid morphological groups
n_syrph_gr <- dt[family == "syrphidae" & !is.na(clustergenera), .N]
n_syrph_gr
round(n_syrph_gr / n_ord * 100, 2) # 20.29%

# N. instances associated with Fig. 12C
round(697 / n_ord * 100, 2)    # 11.69% of all Diptera
round(697 / n_no_fam * 100, 2) # 24.06% of instances with no family

# N. instances outside ROI - FIg 12D
round(182 / n_ord * 100, 2)    # 3.05% of all Diptera
round(182 / n_no_fam * 100, 2) # 6.28% of instances with no family


# Taxa tables -------------------------------------------------------------

# ~ Table 1 - order level --------------------------------------------------

# N box and percent.Note that using n_img = uniqueN(img_path) is not accurate
# because the same image can be counted two times if it contains boxes of two
# different orders.
order_summary_dt <- dt[, .(n_box = .N), keyby = order][
  , percent := round(n_box/sum(n_box) *100, 2)][order(-percent)]
order_summary_dt[, cumul_sum := cumsum(n_box/sum(n_box)*100) %>% round(2)]
# Adding the total row
total_row <- data.table(order = "Total",
                        n_box = sum(order_summary_dt$n_box),
                        percent = round(sum(order_summary_dt$percent), 1))
# Combining the summary data.table with the total row
order_summary_dt <- rbindlist(list(order_summary_dt, total_row), fill=TRUE)
order_summary_dt
#           order n_box percent cumul_sum
# 1:  hymenoptera 20987   59.63     59.63
# 2:      diptera  5963   16.94     76.58
# 3:   coleoptera  3254    9.25     85.82
# 4: thysanoptera  2965    8.42     94.25
# 5:      araneae  1158    3.29     97.54
# 6:    hemiptera   812    2.31     99.84
# 7:  lepidoptera    44    0.13     99.97
# 8:        no_id    11    0.03    100.00
# 9:        Total 35194  100.00        NA


# ~ Appendix Table V - Hymenoptera -----------------------------------------------------------

taxa_cols_hym_all <- c('order', 'suborder', 'infraorder', 'superfamily', 'family', 'genus', 'morphospecies', 'species')

dt_hym_taxa_all <- dt[order == "hymenoptera", .(n_box = .N), keyby = taxa_cols_hym_all][, prc := round(n_box/sum(n_box) *100, 1)][]
dt_hym_taxa_all[]

write.csv(dt_hym_taxa_all, 
          file = './data/cache/table_taxa_counts_hymenoptera_all_taxa_levels.csv',
          row.names = FALSE)


# 'suborder', 'infraorder', 'superfamily', 
taxa_cols_hym <- c('family', 'genus', 'morphospecies', 'species')

dt_hym_taxa <- dt[order == "hymenoptera", .(n_box = .N), keyby = taxa_cols_hym][, prc := round(n_box/sum(n_box) *100, 3)][]

# How many were identified to genus level?
dt_hym_taxa[!is.na(genus), sum(prc)] %>% round(2) # 64.59 %
# How many were identified to species level?
dt_hym_taxa[!is.na(species), sum(prc)] %>% round(2) # 19.36 %

dt_hym_taxa_sum <- dt_hym_taxa[, .(
  family = "TOTAL",
  n_box = sum(n_box), 
  prc = sum( n_box/sum(n_box) ) * 100
)]

dt_hym_taxa_final <- rbindlist(list(dt_hym_taxa, dt_hym_taxa_sum), fill = TRUE)

# Force , as thousand separator so that is passed to the CVS file
dt_hym_taxa_final[, n_box := format(n_box, big.mark = ",", scientific = FALSE)]

# Rename columns with final names
setnames(dt_hym_taxa_final, 
         new = c("Family", "Genus", "Morphospecies", "Species", "Nr. boxes", "% boxes"))

# Prepare the species names. Capitalize 1st letter
dt_hym_taxa_final[, Family := tools::toTitleCase(Family)]
dt_hym_taxa_final[, Genus := tools::toTitleCase(Genus)]

# Replace red_rump with red_tailed 
dt_hym_taxa_final[Morphospecies == "red_rump", Morphospecies := "red_tailed"]
dt_hym_taxa_final[Morphospecies == "white_rump", Morphospecies := "white_tailed"]

# Replace all NA values with ""
dt_hym_taxa_final[is.na(dt_hym_taxa_final)] <- ""

write.csv(dt_hym_taxa_final, 
          file = './data/cache/Appendix_Table_taxa_counts_hymenoptera.csv',
          row.names = TRUE)

# ~ Appendix Table VI - Diptera ---------------------------------------------------------------

taxa_cols_dipt_all <- c('order', 'suborder', 'infraorder', 'superfamily', 'family', 'clustergenera', 'genus', 'species')

dt_dip_taxa_all <- dt[order == "diptera", .(n_box = .N), keyby = taxa_cols_dipt_all][, prc := round(n_box/sum(n_box) *100, 1)][]


write.csv(dt_dip_taxa_all, 
          file = './data/cache/table_taxa_counts_diptera_all_taxa_levels.csv',
          row.names = FALSE)


taxa_cols_dipt <- c('family', 'clustergenera', 'genus', 'species')

dt_dip_taxa <- dt[order == "diptera", .(n_box = .N), keyby = taxa_cols_dipt][, prc := round(n_box/sum(n_box) *100, 3)][]

# How many were identified to genus level?
dt_dip_taxa[!is.na(genus), sum(prc)] %>% round(2) # 26.18 %
# How many were identified to species level?
dt_dip_taxa[!is.na(species), sum(prc)] %>% round(2) # 15.19 %

dt_dip_taxa_sum <- dt_dip_taxa[, .(
  family = "TOTAL",
  n_box = sum(n_box), 
  prc = sum( n_box/sum(n_box) ) * 100
)]

dt_dip_taxa_final <- rbindlist(list(dt_dip_taxa, dt_dip_taxa_sum), fill = TRUE)

# Force , as thousand separator so that is passed to the CVS file
dt_dip_taxa_final[, n_box := format(n_box, big.mark = ",", scientific = FALSE)]

# Rename columns with final names
setnames(dt_dip_taxa_final, 
         new = c("Family", "Cluster genera", "Genus", "Species", "Nr. boxes", "% boxes"))

# Prepare the species names. Capitalize 1st letter
dt_dip_taxa_final[, Family := tools::toTitleCase(Family)]
dt_dip_taxa_final[, Genus := tools::toTitleCase(Genus)]

# Replace all NA values with ""
dt_dip_taxa_final[is.na(dt_dip_taxa_final)] <- ""

write.csv(dt_dip_taxa_final, 
          file = './data/cache/Appendix_Table_taxa_counts_diptera.csv',
          row.names = TRUE)


# Extra - annotation time ---------------------------------------------------------

# We parsed 460,056 images in ~ 1000 hours (approximation).

# Time spent on average per image (parsing trough the folder and placing
# bounding boxes on images with insects):
(1000*3600)/460056
# 7.825134 seconds