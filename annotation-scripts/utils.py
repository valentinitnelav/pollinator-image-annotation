# Python function, equivalent of the get_attributes() from utils.r

import json
import pandas as pd

# Start by creating a row dictionary with only the path and region_id. 
# Then update this dictionary with the contents of shape_attributes and region_attributes. 
# This will add all attributes found in the JSON data to the dictionary. 
# Finally, append the dictionary to the list of rows. 
# After processing all images and regions, convert the list of rows into a DataFrame.
def via_json_to_df(json_file_path):
    """
    Convert a JSON file in the VIA format to a DataFrame.
    :param json_file_path: Path to the JSON file
    :return: DataFrame with the data from the JSON file
    """
    with open(json_file_path) as file:
        via_data = json.load(file)

    img_metadata = via_data["_via_img_metadata"]

    rows = []
    for img_path, metadata in img_metadata.items():
        for region_id, region in enumerate(metadata["regions"]):
            shape_attributes = region["shape_attributes"]
            region_attributes = region["region_attributes"]

            row = {
                "path": img_path,
                "region_id": region_id,
            }
            row.update(shape_attributes)
            row.update(region_attributes)
            rows.append(row)

    df = pd.DataFrame(rows)
    return df
