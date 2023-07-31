# This is a script example for reading a VGG-VIA JSON annotation file with
# bounding boxes into R as data frames. Once they are in data frame format, they
# can be exported to CSV or spreadsheet format.

library(jsonlite)
library(data.table)
library(openxlsx) # optional, for the Excel example
# Load (source) the custom conversion function get_attributes()
source("./annotation-scripts/utils.r")

# E.g.: read the JSON example file ./data/Centaurea-scabiosa-01-jc-vs.json
# This corresponds to field day 2021-07-06

# First read the JSON structure as a list object
json_lst <- fromJSON(txt = "./data/cache/Centaurea-scabiosa-01-jc-vs.json")
# Then parse the list and execute the conversion to data frame
dt <- get_attributes(json_lst)

# Now one can save the dt data frame to a CSV file or to an Excel file

# - CSV file
write.csv(dt, "./data/cache/Centaurea-scabiosa-01-jc-vs.csv", row.names = FALSE)

# - Excel file
wb <- createWorkbook()
addWorksheet(wb, sheetName = "annotation_data")
freezePane(wb, sheet = 1, firstRow = TRUE)
writeDataTable(wb, sheet = 1, x = dt, colNames = TRUE, rowNames = FALSE, withFilter = TRUE)
saveWorkbook(wb, file = "./data/cache/Centaurea-scabiosa-01-jc-vs.xlsx", overwrite = FALSE)
