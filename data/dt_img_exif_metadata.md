# Metadata

## General Information

Metadata for the binary file file dt_img_exif_metadata.rds which contains a tabular dataset with EXIF metadata of each image for the 213 annotated "target-flowers" folders discussed in the manuscript.

It includes 460,056 observations (rows), each representing an image with associated metadata.

### Data Format

The tabular dataset stored in the rds binary file is structured as a `data.table` in R, with the following 18 variables.

1. **Date**: Date of the image capture (character string, format: YYYY-MM-DD)
2. **Plant Folder**: Identifier for the plant species / target flower folder (character string)
3. **Filename**: Name of the image file (character string)
4. **DateTimeOriginal**: Original date and time of image capture (character string, format: YYYY:MM:DD HH:MM:SS)
5. **SubSecTimeOriginal**: Sub-second time of image capture (character string)
6. **Megapixels**: Image resolution in megapixels (character string)
7. **Focal Length**: Focal length used in the image (character string, format: XX.X mm)
8. **Aperture**: Aperture value used (character string)
9. **Shutter Speed**: Shutter speed value (character string)
10. **FNumber**: F-number of the image (character string)
11. **ISO**: ISO sensitivity (character string)
12. **Light Value**: Light value of the image (character string)
13. **Exposure Compensation**: Exposure compensation value (character string)
14. **Make**: Make of the camera used (character string)
15. **Model**: Model of the camera used (character string)
16. **Image Width**: Width of the image in pixels (integer)
17. **Image Height**: Height of the image in pixels (integer)
18. **Orientation**: Orientation of the image (character string)

These values were extracted with the exiftool program for each image: https://exiftool.org/ Many of the EXIF tag names and details about them can be found at https://exiftool.org/TagNames/EXIF.html

Example with running the exiftool command under a Linux operating system given a txt file with the paths to each image (each path separated by a new line):
```sh
# To use 4 CPUs each 1000 images and also time the operation:
time \
cat img_paths.txt | xargs -n 1000 -P 4 exiftool -q -fast2 -csv \
-DateTimeOriginal \
-SubSecTimeOriginal \
-Megapixels \
-FocalLength \
-Aperture \
-ShutterSpeed \
-FNumber \
-ISO \
-LightValue \
-ExposureCompensation \
-Make \
-Model \
-ImageWidth \
-ImageHeight \
-Orientation > img_exif_dimensions_metadata.csv
```
