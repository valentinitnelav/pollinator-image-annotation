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
  , img_prc := round(n_img/sum(n_img) *100, 1)][order(-img_prc)]
#   n_boxes n_rows n_img img_prc
# 1:       1  31901 31901    95.2
# 2:       2   3004  1505     4.5
# 3:       3    285    95     0.3
# 4:       4      4     1     0.0
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


# Appendix Table - List of sampled plant species and number of annotated images. --------------------------------------------------------------

# This was Appendix_Table_II

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


# Taxa tables -------------------------------------------------------------

# ~ order level (Tbl. 1) --------------------------------------------------

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


# ~ Appendix Table - Hymenoptera -----------------------------------------------------------

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


# ~ Appendix Table - Diptera ---------------------------------------------------------------

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


# Annotation time ---------------------------------------------------------

# We parsed 460,056 images in ~ 1000 hours (approximation).

# Time spent on average per image (parsing trough the folder and placing
# bounding boxes on images with insects):
(1000*3600)/460056
# 7.825134 seconds