# pollinator-image-annotation

## Annotation with VGG Image Annotator (VIA)

During the manual annotation process, we utilized the freely available, open-source [VGG Image Annotator (VIA)][1] to enclose any detected insect within a tightly-fitted bounding box and documented its taxonomic order. 

An online demo of the annotation tool can be found at [this link][2]. Below we present our worflow.

We annotated each "plant-folder" with its own JSON file created by the VIA application.

Once you open the via.html file (e.g. double click), the software runs directly in your browser and you should see an empty canvas like this:

![image](https://github.com/valentinitnelav/pollinator-image-annotation/assets/14074269/d839a2c2-d17f-4b72-bb16-b9798692ca9d)

For each plant folder, load the empty JSON template (field_img_template_11_01_2022.json) with predifined attribute tables. 
In the via app, go to menu `Project` then select `Load`, like below:

![image](https://github.com/valentinitnelav/pollinator-image-annotation/assets/14074269/1097c159-e5e3-4530-941d-29f15bdd8433)

Then navigate to find the needed `json` file and open it.

Once the `json` template file is loaded, then we can add an entire folder of images to label/annotate. Go to menu `Project` and select `Add local files`, as below:

![image](https://github.com/valentinitnelav/pollinator-image-annotation/assets/14074269/4bf50919-1533-4adf-ae61-7e070b2e1c53)

Navigate to the folder containing the images you wish to annotate. In the pop-up window, select all the images from the folder by pressing `CTRL + A`. Click `Open` to load the images. Once loaded, the first image from the folder should be visible in the canvas.

Begin annotation by clicking on the initial corner of your desired bounding box and dragging to the opposite corner, aiming to encapsulate the insect snugly, including all extremities such as antennae, which may aid identification:

![image](https://github.com/valentinitnelav/pollinator-image-annotation/assets/14074269/cd5a78c9-123d-4800-a792-107e2deb3318)

Upon releasing the mouse, an attribute table may pop up; disregard this for the moment.

Ensure your bounding box is deselected by clicking elsewhere on the image. Once deselected, navigate to the next image using the right arrow key. Note: if the bounding box is selected, using the arrow keys will simply move the box rather than progress to the next image.

To save the *.json project file with you annotations:

![image](https://github.com/valentinitnelav/pollinator-image-annotation/assets/14074269/036ca99f-2b55-4046-8478-edc039191ab0)

Bear in mind that the JSON file is stored locally in your computer's default Downloads folder. Each time you save, a new JSON file is created, with the operating system adding an index to the file name for distinction; the most recent file corresponds to your latest work.

The software doesn't auto-save, so in case of potential crashes - although rare with VIA - make a habit of saving your work frequently.

### Extra notes:

The 'attribute table' below the image can be toggled on or off using the 'spacebar'. A list of keyboard shortcuts is available on the left side of the VIA app. Remember, 'region' refers to a 'box' in the image.

Each row in the attribute table corresponds to a box. If you need to delete boxes, select the box in the image and press 'd'. To delete all boxes, press 'a' and then 'd'.

Zooming in can be also achieved by hovering the mouse pointer over the image (not the page frame), holding 'CTRL', and scrolling the mouse. This is the same as zooming in on a webpage, but ensure the mouse is over the image. If the mouse hovers over the page frame, the entire page will zoom. To reset the zoom, press 'CTRL + 0'.

Existing attributes within our JSON template project file can be modified as needed. If there are missing orders, you can update the template by adding new option IDs to the 'order' dropdown attribute:

![image](https://github.com/valentinitnelav/pollinator-image-annotation/assets/14074269/944f3666-3e9a-4344-b745-5f481135de18)

[1]: https://www.robots.ox.ac.uk/~vgg/software/via/
[2]: https://www.robots.ox.ac.uk/~vgg/software/via/via_demo.html


# To add

- a guide about how to use the VGG VIA annotation tool, 
- a script example about how to convert from the JSON file format given by VIA to spreadsheets,
- the scripts needed to build any tables and figures in the final manuscript.
