# Script to compute stats regarding the time step between consecutive images and
# session duration per plant-folder (target flower).

# There are sometimes issues because it looks that for some plant-folders, there
# can be unexpected time breaks between the images.

library(data.table)
library(magrittr)
library(ggplot2)
library(scales)

dt <- readRDS(file = './data/dt_img_exif_metadata.rds')

str(dt)
nrow(dt) # 460056


# Get sub-second values ---------------------------------------------------

dt[, subsec := as.integer(SubSecTimeOriginal)]
dt[, range(subsec, na.rm = TRUE)]
# [1]      0 999971

dt[subsec <= 9, .N] / nrow(dt) * 100   # 0.545151 % of them are under   9
dt[subsec <= 59, .N] / nrow(dt) * 100  # 54.60466 % of them are under  59
dt[subsec <= 99, .N] / nrow(dt) * 100  # 96.88473 % of them are under  99
dt[subsec <= 999, .N] / nrow(dt) * 100 # 96.88799 % of them are under 999
dt[subsec > 99, .N] / nrow(dt) * 100   # 3.107448 % of them above      99
# This indicates that SubSecTimeOriginal is most probably hundredths of a second (0-99)

# Handle values over 99 as NA (they are most probably erroneous)
dt[, subsec := ifelse(subsec > 99, NA, subsec)]
dt[is.na(subsec), .N] # 14332

# Example of time conversion
# See https://stackoverflow.com/questions/22037657/milliseconds-in-posixct-class
dt$DateTimeOriginal[1]
# [1] "2021:07:06 13:27:16"
dt$subsec[1]
to_convert <- paste0(dt$DateTimeOriginal[1], ".", sprintf("%02d", as.numeric(dt$subsec[1])))
to_convert
# [1] "2021:07:06 13:27:16.57"
converted <- as.POSIXct(to_convert, 
                        format = "%Y:%m:%d %H:%M:%OS", 
                        tz = "UTC")
converted
# [1] "2021-07-06 13:27:16 UTC"
format(converted, "%Y-%m-%d %H:%M:%OS6")
# [1] "2021-07-06 13:27:16.569999"
# It looks like R rounds down with 0.000001 sec. It's ok for this project

# Now apply that for the entire data table
dt[, time_char := paste0(DateTimeOriginal, ".", sprintf("%02d", as.numeric(subsec))) ]
dt[, time := as.POSIXct(time_char, format = "%Y:%m:%d %H:%M:%OS", tz = "UTC")]
inherits(dt[["time"]], "POSIXct") # TRUE # expect TRUE
# Inspect some values - first 5 rows and last one
dt[c(1:5, .N), .(format(time, "%Y-%m-%d %H:%M:%OS6"))]
#                            V1
# 1: 2021-07-06 13:27:16.569999
# 2: 2021-07-06 13:27:18.579999
# 3: 2021-07-06 13:27:20.579999
# 4: 2021-07-06 13:27:22.579999
# 5: 2021-07-06 13:27:24.579999
# 6: 2021-09-16 17:20:00.130000

# Compute the lagged time diff with the defaults lag=1 & differences = 1 (see
# ?diff). time dif from next; add NA for the last in the group so to get NA.
# Otherwise, it tries to compute with the next from next group and will get huge
# differences.
c(diff(as.numeric(1:3)), NA) # example of diff with the next for 1,2,3; for 3 we cannot compute a time dif

dt[, date_plant_folder := paste(date, plant_folder, sep = "__")]

dt[, `:=`(time_delta = c(diff(as.numeric(time)), NA), 
          prev_filename = shift(filename, type="lag"), # optional for checking
          next_filename = shift(filename, type="lead")), 
   keyby = date_plant_folder]


# ~ Quality check ---------------------------------------------------------

# Check quantiles and the range

dt[, quantile(time_delta, probs = c(0.025, 0.975), na.rm = TRUE)]
#        2.5%     97.5% 
#   0.8699999 2.5500000 

dt[, range(time_delta, na.rm = TRUE)]
# [1] -182.56 1324.56


# ~~ Negative time steps --------------------------------------------------

dt[time_delta < 0, .N] # only 4 cases
dt[time_delta < 0, .N, keyby = date_plant_folder]
#                          date_plant_folder N
# 1: 2021-07-27__Crepis-biennis-ru-01(lense) 1
# 2:       2021-08-04__Centaurea-jacea-bs-03 1
# 3:       2021-08-13__Centaurea-jacea-ru-01 1
# 4:       2021-08-13__Centaurea-jacea-ru-02 1

test <- dt[date_plant_folder == "2021-07-27__Crepis-biennis-ru-01(lense)"]
# Looks like the first 2 images were artifacts and they were setting the phone;
# then the rest look as usual.

test <- dt[date_plant_folder == "2021-08-04__Centaurea-jacea-bs-03"]
# It looks like a bug in the exif metadata. The time extracted with exiftool is
# distorted by ~200 sec for a few images

test <- dt[date_plant_folder == "2021-08-13__Centaurea-jacea-ru-01"]
# Looks like for this folder, the phone reported subsec at really unusual
# values. Set the subsec 0 for the entire folder. This was an older phone we
# took in the field.

test <- dt[date_plant_folder == "2021-08-13__Centaurea-jacea-ru-02"]
# Again, it looks like for one of the images, exiftool returned spurious values.

# Set the time_delta to NA for these negative cases
dt[time_delta < 0, time_delta := NA] 


# ~~ Unexpectedly high values ---------------------------------------------

dt[time_delta > 4, .N] # 101 cases

test <- dt[time_delta > 4, 
           .(n_cases = .N, max = max(time_delta)), 
           keyby = date_plant_folder]

dt[date_plant_folder == "2021-08-04__Daucus-carota-bs-01"][time_delta == max(time_delta, na.rm = TRUE), 
                                                           .(date_plant_folder, filename, time_delta)]
#                  date_plant_folder                filename time_delta
# 1: 2021-08-04__Daucus-carota-bs-01 IMG_20210804_131134.jpg    1324.56
test_2 <- dt[date_plant_folder == "2021-08-04__Daucus-carota-bs-01"]
# Looks like there was an unexpected long break for this plant folder.
# Between IMG_20210804_131134.jpg and IMG_20210804_133339.jpg

dt[date_plant_folder == "2021-07-23__White-Carduus-bs-01"][time_delta == max(time_delta, na.rm = TRUE), 
                                                           .(date_plant_folder, filename, time_delta)]
#                  date_plant_folder                filename time_delta
# 1: 2021-07-23__White-Carduus-bs-01 IMG_20210723_093143.jpg     684.65
test_2 <- dt[date_plant_folder == "2021-07-23__White-Carduus-bs-01"]
# IMG_20210723_093143.jpg - unexpected break after this image
# IMG_20210723_094406.jpg - same as above
# IMG_20210723_093003.jpg - same

# It looks like these big difference indicate unexpected breaks during the recording.

# Let's check smaller time dif
dt[date_plant_folder == "2021-07-23__Picris-hieracioides-bs-01"][time_delta == max(time_delta, na.rm = TRUE), 
                                                                 .(date_plant_folder, filename, time_delta)]
#                        date_plant_folder                filename time_delta
# 1: 2021-07-23__Picris-hieracioides-bs-01 IMG_20210723_104110.jpg          8
test_2 <- dt[date_plant_folder == "2021-07-23__Picris-hieracioides-bs-01"]
# This jump in time step seems also legit, but unexpected.

dt[date_plant_folder == "2021-07-13__Trifolium pratense"][time_delta == max(time_delta, na.rm = TRUE), 
                                                          .(date_plant_folder, filename, time_delta)]
#                 date_plant_folder                filename time_delta
# 1: 2021-07-13__Trifolium pratense IMG_20210713_111506.jpg       4.16
test_2 <- dt[date_plant_folder == "2021-07-13__Trifolium pratense"]
# This also looks like a legit break and this folder is characterized by a
# longer time step. There is also no field notes for this folder. It could be
# that the phone started to malfunction or was overheating?

# This could indicated that the student helpers in the field might have
# temporally stopped sometimes the phones to adjust them, other times perhaps
# the phones lagged due to overheating, as it was reported, or complete shut
# down.

# Since the lag of 8 seconds also seems legit and since they are not that many
# cases, I decided to set anything above a time lag of 8 second to NA.
# This will keep at most, the 8 seconds lag as a legit values, rest are rest to NA:
dt[time_delta > 8, time_delta := NA] 

dt[is.na(time_delta), .N] # 371
# These is just tiny fraction of the images, so setting them to NA is acceptable.


# Compute stats -----------------------------------------------------------

# Recompute quantile and range
dt[, quantile(time_delta, probs = c(0.025, 0.975), na.rm = TRUE)]
#        2.5%     97.5% 
#   0.8699999 2.5500000 

dt[, range(time_delta, na.rm = TRUE)]
# [1] 0 8

dt[, mean(time_delta, na.rm = TRUE)]
# [1] 1.6254

dt[, sd(time_delta, na.rm = TRUE)]
# [1] 0.4038001

dt[, median(time_delta, na.rm = TRUE)]
# [1] 1.61

# Stats per plant folder
dt_delta_plant <- dt[, .(time_delta_mean = mean(time_delta, na.rm = TRUE),
                         time_delta_median = median(time_delta, na.rm = TRUE),
                         total_duration = max(time, na.rm = TRUE) - min(time, na.rm = TRUE),
                         n_img = .N), 
                     keyby = date_plant_folder]

dt_delta_plant[, range(time_delta_mean)]
# [1] 0.8910819 3.1270751

dt_delta_plant[, range(time_delta_mean) %>% round(1)]
# [1] 0.9 3.1

# For 2021-07-13__Trifolium pratense, we get a average time delta of 3.127075
# Indeed, I think we set it lower by accident.

# The overall average
dt_delta_plant[, mean(time_delta_mean)] # 1.680592 seconds
# This value is valid for the plant folders that we parsed for annotation.
dt_delta_plant[, sd(time_delta_mean)]  #  0.3216689 seconds

dt_delta_plant[, range(time_delta_median)]
# [1] 1.0 3.1
dt_delta_plant[, median(time_delta_median)]
# [1] 1.62


# Histogram of time step --------------------------------------------------

dt_step <- dt[!is.na(time_delta), .(date_plant_folder, filename, time_delta)]

quantiles <- quantile(dt_step$time_delta, probs = c(0.025, 0.975))
quantiles
#        2.5%     97.5% 
#   0.8699999 2.5500000 

mean(dt_step$time_delta)
# [1] 1.6254

gg_time_step <- ggplot(dt_step, aes(x = time_delta)) +
  geom_histogram(binwidth = 0.1, color = "black", fill = "white") +
  geom_vline(aes(xintercept = quantiles[1]), color = "red", linetype = "dashed", linewidth = 0.5) +
  geom_vline(aes(xintercept = mean(dt_step$time_delta)), color = "blue", linetype = "dashed", linewidth = 0.5) +
  geom_vline(aes(xintercept = quantiles[2]), color = "red", linetype = "dashed", linewidth = 0.5) +
  # scale_x_continuous(breaks = 0:23) +
  scale_y_continuous(labels = comma_format()) +
  xlab("Time step (seconds)") +
  ylab("Frequency") +
  theme_bw(base_size = 10) +
  theme(axis.title = element_text(size = 10), # Set axis & legend title size to 10
        legend.title = element_text(size = 10))

gg_time_step

ggsave("./figures/hitsogram_time_step.jpg", gg_time_step, width = 12, height = 8, units = "cm", dpi = 300)


# Time duration per plant folder ------------------------------------------

# See dt_delta_plant computed above

dt_delta_plant

quantile(dt_delta_plant$total_duration, probs = c(0.025, 0.975))
# Time differences in secs
#       2.5%    97.5% 
#   2600.379 4046.509 

dt_delta_plant[, range(total_duration)]
# Time differences in secs
# [1]  890.81 4460.16

# 2021-08-04__cichorium-intybus-AS-01 has the longest duration 

# This is because there was no automatic stop for the phones. It looks like the
# longer ones were due to the fact that they forgot to stop them after 1 hour

dt_delta_plant[, range(total_duration) %>% round(0)]
# Time differences in secs
# [1]  891 4460

dt_delta_plant[, mean(total_duration)]
# Time difference of 3552.922 secs

dt_delta_plant[, sd(total_duration)]
# [1] 371.9507

dt_delta_plant[, median(total_duration)]
# Time difference of 3601.9 secs

# Histogram
quantiles_dur <- quantile(dt_delta_plant$total_duration, probs = c(0.025, 0.975))

gg_duration <- ggplot(dt_delta_plant, aes(x = total_duration)) +
  geom_histogram(binwidth = 60, color = "black", fill = "white") +
  geom_vline(aes(xintercept = quantiles_dur[1]), color = "red", linetype = "dashed", linewidth = 0.5) +
  geom_vline(aes(xintercept = mean(dt_delta_plant$total_duration)), color = "blue", linetype = "dashed", linewidth = 0.5) +
  geom_vline(aes(xintercept = quantiles_dur[2]), color = "red", linetype = "dashed", linewidth = 0.5) +
  # scale_x_continuous(breaks = 0:23) +
  scale_y_continuous(labels = comma_format()) +
  xlab("Duration (seconds)") +
  ylab("Frequency") +
  theme_bw(base_size = 10) +
  theme(axis.title = element_text(size = 10), # Set axis & legend title size to 10
        legend.title = element_text(size = 10))

gg_duration

ggsave("./figures/hitsogram_recording_duration.jpg", gg_duration, width = 12, height = 8, units = "cm", dpi = 300)
