# Script to create Figure in Appendix Figure I. Frequency of images by hour of the day 

library(data.table)
library(magrittr)
library(stringr)
library(lubridate)
library(ggplot2)
library(scales) # for thousand separators on graph axis

dt_img <- readRDS(file = './data/dt_img_exif_metadata.rds')

str(dt_img)

# Get time / hour ----------------------------------------------------------------

# Extract hour from file name, and for those without time in filename, add the
# hour from exif metadata

# Helper function to extract the 6 digits after the 2nd "_" in filename.
# filename can contain things like IMG_0376.JPG or IMG_20210916_171035.jpg or
# IMG_20210916_171035_1.jpg. I want to extract the 6 digit pattern after the
# second "_" character.
extract_time <- function(x) {
  parts <- strsplit(x, "_")[[1]]
  if (length(parts) < 3) {
    return(NA)
  } else {
    return(substr(parts[3], start=1, stop=6))
  }
}
dt_img[, hhmmss_from_filename := sapply(filename, extract_time)]

dt_img[! is.na(hhmmss_from_filename), hh := substr(hhmmss_from_filename, 1, 2)]

dt_img[is.na(hh), .N] # 7905

dt_img[, .N, keyby = hh]

dt_img[, date_time_exif := tstrsplit(DateTimeOriginal, split = " ", fixed = TRUE)[[2]]]
dt_img[, hh_exif := substr(date_time_exif, 1, 2)]

dt_img[is.na(hh), hh := hh_exif]
dt_img[, hour := as.integer(hh)]

dt_img[, .N, keyby = hour]
dt_img[is.na(hour)] # 4 cases where time cannot be extracted; this is acceptable

dt <- dt_img[!is.na(hour), .(hour)]

# Histogram -------------------------------------------------------

quantiles <- quantile(dt$hour, probs = c(0.025, 0.975))
quantiles
# 2.5% 97.5% 
#   9    14 

gg_hours <- ggplot(dt, aes(x = hour)) +
  geom_histogram(binwidth = 1, color = "black", fill = "white") +
  geom_vline(aes(xintercept = quantiles[1]), color = "red", linetype = "dashed", linewidth = 1) +
  geom_vline(aes(xintercept = quantiles[2]), color = "red", linetype = "dashed", linewidth = 1) +
  scale_x_continuous(breaks = 0:23) +
  scale_y_continuous(labels = comma_format()) +
  xlab("Hour of the Day") +
  ylab("Frequency") +
  theme_bw(base_size = 10) +
  theme(axis.title = element_text(size = 10), # Set axis & legend title size to 10
        legend.title = element_text(size = 10))

# Save to .eps and .pdf formats as required by the journal
ggsave("./figures/hitsogram_hour.eps", gg_hours, width = 12, height = 8, units = "cm")
ggsave("./figures/hitsogram_hour.pdf", gg_hours, width = 12, height = 8, units = "cm")
# For visualization in drafts, save also to jpg format
ggsave("./figures/hitsogram_hour.jpg", gg_hours, width = 12, height = 8, units = "cm", dpi = 300)
