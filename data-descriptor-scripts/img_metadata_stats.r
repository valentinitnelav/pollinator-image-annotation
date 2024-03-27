# Script to compute descriptive stats about image metadata for Table 3.

library(data.table)
library(magrittr)

# All images, including the ones without insects
dt_img_meta <- readRDS(file = './data/dt_img_exif_metadata.rds')
str(dt_img_meta)
dt_img_meta[, key := paste(date, plant_folder, filename)]

# Annotated bounding boxes (a row = a bounding box)
dt_box <- readRDS(file = "./data/dt_box_annotation.rds")
str(dt_box)
dt_box[, key := paste(date, plant_folder, filename)]


# Image resolution --------------------------------------------------------

dt_img_meta[, res := paste(ImageWidth, ImageHeight, sep = " X ")]
dt_img_meta[, mpx := ImageWidth * ImageHeight / 10^6]

dt_img_meta[, .(n_img = .N), by = .(res, mpx)][, p := round(n_img/sum(n_img) * 100, 4)][order(-n_img)]

# Merge image metadata with box metadata
dt <- merge(dt_box, dt_img_meta, by = "key", all.x = TRUE, all.y = FALSE)

dt[, .(n_img = uniqueN(key)), keyby = .(res)][, perc := round(n_img/sum(n_img) * 100, 2)][order(-n_img)]
#            res n_img  perc
# 1: 1600 X 1200 30489 91.01
# 2: 1200 X 1600  1613  4.81
# 3: 2400 X 1600   654  1.95
# 4: 2048 X 1536   291  0.87
# 5:  1280 X 720   252  0.75
# 6:  1152 X 864   203  0.61


# Models ------------------------------------------------------------------

dt[, .(n_img = uniqueN(key)), keyby = .(Make, Model)][, perc := round(n_img/sum(n_img) * 100, 2)][order(-n_img)]
#         Make          Model     N  perc
# 1: Blackview            A60 31541 94.15
# 2:    HOMTOM           HT50  1051  3.14
# 3:     Canon Canon EOS 200D   653  1.95
# 4:    HUAWEI       WAS-LX1A   252  0.75
# 5:      <NA>           <NA>     5  0.01

# What are the NAs?
dt[is.na(Make), .(key, res)]
dt[is.na(Model), .(key, res)]
#                                                           key         res
# 1:              2021-07-06 Centaurea-scabiosa-01 IMG_0664.JPG 2400 X 1600
# 2:   2021-07-06 Centaurea-scabiosa-03 IMG_20210706_141321.jpg  1152 X 864
# 3:   2021-07-29 Centaurea-jacea-bs-04 IMG_20210729_115611.jpg 1600 X 1200
# 4: 2021-07-29 Cichorium-intybus-ru-01 IMG_20210729_102656.jpg 1600 X 1200
# 5:         2021-07-29 Hypericum-01-EC IMG_20210729_114412.jpg 1600 X 1200

# Make corrections
dt[(date.x == "2021-07-06" & plant_folder.x == "Centaurea-scabiosa-01"), .(Make, Model)] %>% unique(by = c("Make", "Model"))
dt[key == "2021-07-06 Centaurea-scabiosa-01 IMG_0664.JPG", ":=" (Make = "Canon", Model = "Canon EOS 200D")]

dt[(date.x == "2021-07-06" & plant_folder.x == "Centaurea-scabiosa-03"), .(Make, Model)] %>% unique(by = c("Make", "Model"))
dt[key == "2021-07-06 Centaurea-scabiosa-03 IMG_20210706_141321.jpg", ":=" (Make = "HOMTOM", Model = "HT50")]

dt[(date.x == "2021-07-29" & plant_folder.x == "Centaurea-jacea-bs-04"), .(Make, Model)] %>% unique(by = c("Make", "Model"))
dt[key == "2021-07-29 Centaurea-jacea-bs-04 IMG_20210729_115611.jpg", ":=" (Make = "Blackview", Model = "A60")]

dt[(date.x == "2021-07-29" & plant_folder.x == "Cichorium-intybus-ru-01"), .(Make, Model)] %>% unique(by = c("Make", "Model"))
dt[key == "2021-07-29 Cichorium-intybus-ru-01 IMG_20210729_102656.jpg", ":=" (Make = "Blackview", Model = "A60")]

dt[(date.x == "2021-07-29" & plant_folder.x == "Hypericum-01-EC"), .(Make, Model)] %>% unique(by = c("Make", "Model"))
dt[key == "2021-07-29 Hypericum-01-EC IMG_20210729_114412.jpg", ":=" (Make = "Blackview", Model = "A60")]


dt[, .(n_img = uniqueN(key)), keyby = .(Make, Model)][, perc := round(n_img/sum(n_img) * 100, 2)][order(-n_img)]
#         Make          Model n_img  perc
# 1: Blackview            A60 31544 94.16
# 2:    HOMTOM           HT50  1052  3.14
# 3:     Canon Canon EOS 200D   654  1.95
# 4:    HUAWEI       WAS-LX1A   252  0.75


dt[, .(n_img = uniqueN(key)), keyby = .(Make, Model, res)][, perc := round(n_img/sum(n_img) * 100, 2)][order(Make, -n_img)]
#         Make          Model         res n_img  perc
# 1: Blackview            A60 1600 X 1200 29778 88.88
# 2: Blackview            A60 1200 X 1600  1613  4.81
# 3: Blackview            A60 2048 X 1536   153  0.46
# 4:     Canon Canon EOS 200D 2400 X 1600   654  1.95
# 5:    HOMTOM           HT50 1600 X 1200   711  2.12
# 6:    HOMTOM           HT50  1152 X 864   203  0.61
# 7:    HOMTOM           HT50 2048 X 1536   138  0.41
# 8:    HUAWEI       WAS-LX1A  1280 X 720   252  0.75
