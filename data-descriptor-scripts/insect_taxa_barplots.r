# R scripts to create the barplot figures in manuscript - barplots of taxa level
# identification

library(data.table)
library(magrittr)
library(ggplot2)
library(ggtext) # text rendering support for ggplot2
library(patchwork)
library(scales) # for thousand separators on graph axis
library(tidyr)
library(forcats)

# The annotated data. Created after using annotation_data_check.r
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


# Fig. 3 - Hymenoptera ----------------------------------------------------

# ~ Fig 3 A - all -------------------------------------------------------------

what_order <- 'hymenoptera'
taxa_cols <- c('order', 'family', 'genus', 'morphospecies', 'species')
dt_taxa_hym <- dt[order == what_order, .(n_box = .N), keyby = taxa_cols]

non_na_counts <- dt[order == what_order, lapply(.SD, function(x) sum(!is.na(x))), .SDcols = taxa_cols]
non_na_counts
#    order family genus morphospecies species
# 1: 20987  18849 13556          5063    4064

# Prepare data format for ggplot2
non_na_counts_long <- melt(non_na_counts, variable.name = "Variable", value.name = "Count")
# ignore the warning
non_na_counts_long

# Calculate the percentages
order_count <- non_na_counts_long[Variable == "order", Count]
non_na_counts_long[, Percentage := Count / order_count * 100]
non_na_counts_long
#         Variable Count Percentage
# 1:         order 20987  100.00000
# 2:        family 18849   89.81274
# 3:         genus 13556   64.59237
# 4: morphospecies  5063   24.12446
# 5:       species  4064   19.36437

# Prepare a custom stacked barplot

# Initialize a data table for Apis mellifera and other species at the species level
dominant_sp <- "Apis mellifera"
n_apis <- dt_taxa_hym[species == "mellifera", n_box]
n_sp <- non_na_counts$species
species_count <- data.table(Variable = rep("species", 2),
                            Count = c(n_apis, (n_sp - n_apis)),
                            Species = c(dominant_sp, "Other species"))

# Add zero-count entries for Apis mellifera at all other levels. This will
# helping with creating a fake stack (zero) on top of the bars for other taxa
# levels, except for species
zero_counts <- data.table(Variable = c('order', 'family', 'genus', 'morphospecies'),
                          Count = 0,
                          Species = dominant_sp)

# Create the data table for ggplot2 to make the custom stacked barplot
appended_data <- rbindlist(list(non_na_counts_long[Variable != "species", .(Variable, Count)],
                                species_count, 
                                zero_counts), 
                           fill=TRUE)

# Capitalize first letter of each level in the factor
levels(appended_data$Variable) <- tools::toTitleCase(levels(appended_data$Variable))
levels(appended_data$Variable)[2] <- "Family - all"
color_palette <- setNames(c("steelblue", "darkolivegreen"), c(dominant_sp, "Other species"))
color_palette

gg_hym_a <- ggplot(appended_data, aes(x = Variable, y = Count, fill = Species)) +
  geom_bar(stat = "identity") +
  xlab("Taxonomic level") +
  ylab("Instance count\n(bounding boxes)") +
  # Calculate the percentages directly here
  scale_y_continuous(labels = comma_format(),
                     sec.axis = sec_axis(transform = ~ . / order_count * 100, 
                                         name = "%",
                                         breaks = seq(0, 100, by = 10))) +
  scale_fill_manual(values = color_palette,
                    breaks = names(color_palette)) +
  # Used the breaks argument because will ignore the NA values in the legend but not on the cavas
  theme_bw() +
  theme(legend.position = "none", # remove legend for this one - helps with patching,
        axis.title = element_text(size = 10),
        axis.title.x = element_blank(),
        # Rotate x-axis labels 45 degrees
        axis.text.x = element_text(angle = 30, vjust = 1, hjust=1))

gg_hym_a


# ~ Fig 3 B - only pollinator families ------------------------------------------------

taxa_cols <- c('family', 'genus', 'morphospecies', 'species')
non_pollinator_fam <- c("cynipidae", "formicidae", "vespidae")
dt_subset <- dt[order == "hymenoptera"][!is.na(family)][! family %in% non_pollinator_fam]
dt_taxa_hym <- dt_subset[, .(n_box = .N), keyby = taxa_cols]

non_na_counts <- dt_subset[, lapply(.SD, function(x) sum(!is.na(x))), .SDcols = taxa_cols]
non_na_counts
#    family genus morphospecies species
# 1:  16031 13556          5063    4064

# Prepare data format for ggplot2
non_na_counts_long <- melt(non_na_counts, variable.name = "Variable", value.name = "Count")
# ignore the warning
non_na_counts_long

# Calculate the percentages
family_count <- non_na_counts_long[Variable == "family", Count]
non_na_counts_long[, Percentage := Count / family_count * 100]
non_na_counts_long
#         Variable Count Percentage
# 1:        family 16031  100.00000
# 2:         genus 13556   84.56116
# 3: morphospecies  5063   31.58256
# 4:       species  4064   25.35088

# Prepare a custom stacked barplot

# Add zero-count entries for Apis mellifera at all other levels. This will
# helping with creating a fake stack (zero) on top of the bars for other taxa
# levels, except for species
zero_counts <- data.table(Variable = c('family', 'genus', 'morphospecies'),
                          Count = 0,
                          Species = dominant_sp)

# Create the data table for ggplot2 to make the custom stacked barplot
appended_data <- rbindlist(list(non_na_counts_long[Variable != "species", .(Variable, Count)],
                                species_count, 
                                zero_counts), 
                           fill=TRUE)

# Capitalize first letter of each level in the factor
levels(appended_data$Variable) <- tools::toTitleCase(levels(appended_data$Variable))
levels(appended_data$Variable)[1] <- "Family without:\n Cynipidae,\n Formicidae,\n Vespidae"
color_palette <- setNames(c("steelblue", "darkolivegreen"), 
                          c(dominant_sp, "Other species"))
color_palette

# Format dominant_sp for italics. It didn't work to format it directly with setNames() above,
# because somehow it is not rendered by ggtext::element_markdown() below.
dominant_sp_label <- paste0("*", dominant_sp, "*")  # Markdown-style italics

gg_hym_b <- ggplot(appended_data, aes(x = Variable, y = Count, fill = Species)) +
  geom_bar(stat = "identity") +
  xlab("Taxonomic level") +
  ylab("Instance count\n(bounding boxes)") +
  # Calculate the percentages directly here
  scale_y_continuous(labels = comma_format(),
                     sec.axis = sec_axis(transform = ~ . / family_count * 100, 
                                         name = "%",
                                         breaks = seq(0, 100, by = 10))) +
  scale_fill_manual(values = color_palette,
                    labels = c(dominant_sp_label, "Other species"),  # Italicized label for legend
                    breaks = names(color_palette)) +
  # Used the breaks argument because will ignore the NA values in the legend but not on the cavas
  theme_bw() +
  theme(axis.title = element_text(size = 10), # Set axis & legend title size to 10
        legend.title = element_text(size = 10),
        legend.position = "bottom",
        # Render Markdown in legend
        legend.text = ggtext::element_markdown(size = 10),
        # Rotate x-axis labels 45 degrees
        axis.text.x = element_text(angle = 30, vjust = 1, hjust=1))

gg_hym_b



# Combine panels
gg_hym <- (gg_hym_a / gg_hym_b) +
  plot_annotation(tag_levels = 'A', tag_suffix = '')
# theme(axis.title.y=element_blank()) # if you need to remove an axis title
gg_hym

# Save to .eps and .pdf formats as required by the journal
# https://www.pollinationecology.org/index.php/jpe/instructions_authors - 16 cm width 
ggsave("./figures/fig-3.eps", gg_hym, width = 12, height = 16, units = "cm")
ggsave("./figures/fig-3.pdf", gg_hym, width = 12, height = 16, units = "cm")
# For visualization in drafts, save also to jpg format
ggsave("./figures/fig-3.jpg", gg_hym, width = 12, height = 16, units = "cm", dpi = 300)


# Fig 10 - Diptera -----------------------------------------------------------------

what_order <- 'diptera'
taxa_cols <- c('order', 'family', 'genus', 'clustergenera', 'species')
dt_taxa_dip <- dt[order == what_order, .(n_box = .N), keyby = taxa_cols]

non_na_counts <- dt[order == what_order, lapply(.SD, function(x) sum(!is.na(x))), .SDcols = taxa_cols]
# Rename family to family/family-cluster
setnames(non_na_counts, 
         old = c("family", "clustergenera"), 
         new = c("family/fam.-cluster", "morphological-cluster"))
non_na_counts
#     order family/family-cluster genus genera-cluster species
# 1:  5963                  3066  1593           1210     906

# Prepare data format for ggplot2
non_na_counts_long <- melt(non_na_counts, variable.name = "Variable", value.name = "Count")
# ignore the warning
non_na_counts_long

# Calculate the percentages
order_count <- non_na_counts_long[Variable == "order", Count]
non_na_counts_long[, Percentage := Count / order_count * 100]
non_na_counts_long
#               Variable Count Percentage
#                 <fctr> <int>      <num>
# 1:               order  5963  100.00000
# 2: family/fam.-cluster  3066   51.41707
# 3:               genus  1561   26.17810
# 4:      genera-cluster  1242   20.82844
# 5:             species   906   15.19369

# Prepare a custom stacked barplot

# Initialize a data table for Myathropa florea and other species at the species level
dominant_sp <- "Myathropa florea"
n_mflo <- dt_taxa_dip[species == "florea", n_box]
n_sp <- non_na_counts$species
species_count <- data.table(Variable = rep("species", 2),
                            Count = c(n_mflo, (n_sp - n_mflo)),
                            Species = c(dominant_sp, "Other species"))

# Add zero-count entries for Myathropa florea at all other levels. This will
# helping with creating a fake stack (zero) on top of the bars for other taxa
# levels, except for species
zero_counts <- data.table(Variable = names(non_na_counts),
                          Count = 0, # recycling/repetition of 0 happens automatically 
                          Species = dominant_sp)

# Create the data table for ggplot2 to make the custom stacked barplot
appended_data <- rbindlist(list(non_na_counts_long[Variable != "species", .(Variable, Count)],
                                species_count, 
                                zero_counts), 
                           fill = TRUE)

# Capitalize first letter of each level in the factor
levels(appended_data$Variable) <- tools::toTitleCase(levels(appended_data$Variable))
color_palette <- setNames(c("steelblue", "darkolivegreen"), 
                          c(dominant_sp, "Other species"))

# Format dominant_sp for italics. It didn't work to format it directly with setNames() above,
# because somehow it is not rendered by ggtext::element_markdown() below.
dominant_sp_label <- paste0("*", dominant_sp, "*")  # Markdown-style italics

gg_dipt <- ggplot(appended_data, aes(x = Variable, y = Count, fill = Species)) +
  geom_bar(stat = "identity") +
  xlab("Taxonomic level") +
  ylab("Instance count (bounding boxes)") +
  # Calculate the percentages directly here
  scale_y_continuous(labels = comma_format(),
                     sec.axis = sec_axis(transform = ~ . / order_count * 100, 
                                         name = "%",
                                         breaks = seq(0, 100, by = 10))) +
  scale_fill_manual(values = color_palette,
                    labels = c(dominant_sp_label, "Other species"),  # Italicized label for legend
                    breaks = names(color_palette)) +
  # Used the breaks argument because will ignore the NA values in the legend but not on the cavas
  theme_bw() +
  theme(axis.title = element_text(size = 10), # Set axis & legend title size to 10
        legend.title = element_text(size = 10),
        # Render Markdown in legend
        legend.text = ggtext::element_markdown(size = 10),
        # Rotate x-axis labels 45 degrees
        axis.text.x = element_text(angle = 30, vjust = 1, hjust=1))

gg_dipt

# Save to .eps and .pdf formats as required by the journal
ggsave("./figures/fig-10.eps", gg_dipt, width = 12, height = 8, units = "cm")
ggsave("./figures/fig-10.pdf", gg_dipt, width = 12, height = 8, units = "cm")
# For visualization in drafts, save also to jpg format
ggsave("./figures/fig-10.jpg", gg_dipt, width = 12, height = 8, units = "cm", dpi = 300)


# ~ (extra) Diptera - Option with all species ---------------------------------------------------

# Since there are only 3 species, an option would be to plot them all in the species bar

species_count <- dt_taxa_dip[!is.na(species), 
                             .(Variable = "species",
                               Count = sum(n_box)), 
                             by = .(genus, species)]
species_count[, genus := tools::toTitleCase(genus)]
species_count[, Species := paste(genus, species)]
species_count[, genus := NULL]
species_count[, species := NULL]
species_count
#    Variable Count                Species
#      <char> <int>                 <char>
# 1:  species   224   Episyrphus balteatus
# 2:  species    11 Helophilus trivittatus
# 3:  species   671       Myathropa florea

zero_counts <- data.table(Variable = names(non_na_counts),
                          Count = 0, # recycling/repetition of 0 happens automatically 
                          Species = NA_character_)

appended_data <- rbindlist(list(non_na_counts_long[Variable != "species", .(Variable, Count)],
                                species_count, 
                                zero_counts), 
                           fill = TRUE)

color_palette <- setNames(c("steelblue", "darkolivegreen", "red"), 
                          species_count$Species)

gg_dipt <- ggplot(appended_data, aes(x = Variable, y = Count, fill = Species)) +
  geom_bar(stat = "identity") +
  xlab("Taxonomic level") +
  ylab("Instance count (bounding boxes)") +
  # Calculate the percentages directly here
  scale_y_continuous(labels = comma_format(),
                     sec.axis = sec_axis(transform = ~ . / order_count * 100, 
                                         name = "%",
                                         breaks = seq(0, 100, by = 10))) +
  scale_fill_manual(values = color_palette,
                    breaks = names(color_palette)) +
  # Used the breaks argument because will ignore the NA values in the legend but not on the cavas
  theme_bw() +
  theme(axis.title = element_text(size = 10), # Set axis & legend title size to 10
        legend.title = element_text(size = 10),
        # Rotate x-axis labels 45 degrees
        axis.text.x = element_text(angle = 30, vjust = 1, hjust=1))

gg_dipt

# But Helophilus Trivittatus has so few cases (boxes) that it cannot be
# distinguished from Episyrphus Balteatus and Myathropa Florea

