# R function to get box attributes and file information from annotation json file
# generated with the VGG image annotator (VIA). It returns a data table.

# FYI: x=0, y=0 coordinates refers to the upper corner of the image.
get_attributes <- function(json_lst){
  img_meta <- json_lst[["_via_img_metadata"]]
  
  # Get a data table with image name, shape and region attributes
  
  regions_lst <- lapply(img_meta, `[[`, "regions")
  
  # Create a header data frame to force all attribute names. This is needed
  # because sometimes some attribute names might be missing because the annotator
  # didn't fill in that information. When the rbind takes place it can happen to
  # omit an entire attribute name because was never assigned anything to it
  # during the annotation process.
  
  # For shape attributes (e.g. boxes themselves)
  names_of_shape_attributes <- c("name", "x", "y", "width", "height")
  df_header <- data.frame(matrix(nrow = 0, ncol = length(names_of_shape_attributes)))
  colnames(df_header) <- names_of_shape_attributes
  shape_attributes_lst <- lapply(regions_lst, `[[`, "shape_attributes")
  dt_shape_attributes <- rbindlist(l = c(list(df_header), shape_attributes_lst),
                                   fill = TRUE, use.names = TRUE, idcol = "via_img_id")
  
  # fore region attributes (e.g. taxa information)
  names_of_region_attributes <- names(json_lst[["_via_attributes"]][["region"]])
  df_header = data.frame(matrix(nrow = 0, ncol = length(names_of_region_attributes)))
  colnames(df_header) <- names_of_region_attributes
  region_attributes_lst <- lapply(regions_lst, `[[`, "region_attributes")
  dt_region_attributes <- rbindlist(l = c(list(df_header), region_attributes_lst),
                                    fill = TRUE, use.names = TRUE, idcol = "via_img_id")
  
  attr_dt <- cbind(dt_shape_attributes, dt_region_attributes[, !"via_img_id"]) # assumes via_img_id-s match
  # if you use merge, then it creates unwanted duplicates when there are more than
  # 1 boxes (regions)
  
  # In attributes there are a lot of "", they will converted to NA for consistency
  for (j in seq_len(ncol(attr_dt)))
    set(attr_dt, which(attr_dt[[j]] == ""), j, value = NA)
  # https://stackoverflow.com/a/7249454/5193830
  
  dt <- data.table(via_img_id = names(img_meta),
                   filename = sapply(img_meta, `[[`, "filename"),
                   size = sapply(img_meta, `[[`, "size"))
  
  dat <- merge(dt, attr_dt, by = "via_img_id", all.x = TRUE)
  dat[, id_box := ifelse(is.na(name), yes = NA_integer_, no = 1:.N), by = filename]
  # use NA_integer_ to avoid conversion of integers to logic (warnings will be
  # displayed if that happens, but the integers are converted to TRUE/FALSE)
  return(dat[])
}