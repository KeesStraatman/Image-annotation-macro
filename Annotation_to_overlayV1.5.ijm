// Macro to add a Rectangular, Oval, Freehand, Straight Line, Arrow or Text selection to an 
// overlay. The user can select the slice and frame numbers to add this selection.

// Kees Straatman, University of Leicester, 12 October 2015

// version1.2 (Updated 29 May 2017):
// - can handle when there is no selection and does not exit the macro.
// - Instead of asking user in startmenu for first and last frame/slice for their
//   selction the user can now move trough the image to set these.  

// Version1.3 (29 May 2018):
// - Resolved a bug causing a flatten error message in single channel time series
// - Improved "Flatten" of stacks
// - Improved the menu so the user is only asked once if the image should be "Flattened". 

// Version 1.4 (22 August 2019)
// - Check if an image is open.
// - Resolved a bug in time series.
// - Added the option to move the selection after creation after a request from Jayne Squirrell.

// Version 1.5 (24 August 2020)
// - Resolved a bug that caused wrong ROI selections in Hyperstacks.
// - Included a warning that when a multi-channel image is used for flattening only the first channel should
//   be used for annotation.
// - Added the option to select annotation color.

macro Annotation_to_overlay{
	t=0; // counter for menu item "Flatten" if it is used more than once
	answer = 1;	

	// Check for correct image
	if (nImages == 0) exit("Image required");

	while (answer == 1){
		getDimensions(width, height, channels, slices, frames);
		if ((slices==1)&&(frames==1)) exit("Sorry, this macro requires a z-stack and/or time series.");
		if (isOpen("ROI Manager")) {
			roiManager("reset");
		}

		// Create dialog window
		Dialog.create("Create overlay");
		
			items = newArray("Rectangular", "Oval", "Freehand", "Straight Line", "Arrow", "Text");
			color = newArray("red","green","blue","yellow","cyan","magenta","black","grey","white","orange","pink");
			Dialog.addRadioButtonGroup("Annotation to add:", items, 2, 3, "Rectangular");
			Dialog.addChoice("Selection Color", color, "red")
			Dialog.addCheckbox ("Requires to move annotation after creation.", false);
			if (t==0){
				Dialog.addCheckbox("Flatten image when finished.", false);
				if (channels>1){
					Dialog.addMessage("If you want to flatten this multi-channel image,\nyou have to make all annotations in the first channel.") 
				}
				
			}
		Dialog.show();

		// Collect data from dialog window

		selection = Dialog.getRadioButton;
		if (selection=="Rectangular") setTool("Rectangular");
		if (selection=="Oval") setTool("Oval");
		if (selection=="Freehand") setTool("Freehand");
		if (selection=="Straight Line") setTool("Straight Line");
		if (selection=="Arrow") setTool("Arrow");
		if (selection=="Text") setTool("Text");
		color = Dialog.getChoice();
		selectionMove = Dialog.getCheckbox;
		if (t==0){
			Fl = Dialog.getCheckbox;
			t=1;
			
		}
		run("Colors...", "foreground="+color+" background=black selection="+color);

		// Draw ROI on overlay	
		waitForUser("Go to the first slice/frame to start your selection.\nDraw your "+selection+" and click \"OK\"");
		Stack.getPosition(channelStart, Zstart, start);
		if (selectionType()>-1 )roiManager("Add"); 	// Check if there is a selection and add to ROI manager
		waitForUser("Go to the last slice/frame for this selection and click \"OK\".");
		Stack.getPosition(channelEnd, Zend, end);
		
		if ((Stack.isHyperstack== true)&&(roiManager("count")>0)){	
			for (i=Zstart; i<=Zend;i++){
				for (j=start; j<=end;j++){
					for (c=channelStart; c<=channelEnd; c++){
						roiManager("select",0);
						Roi.setPosition(c, i, j);
						roiManager("Add");
					}
				}
			}
			// remove ROI used for selection
			roiManager("select",0);
			roiManager("delete");
			
			// Allow to move selection
			if (selectionMove==true){
			for (i=1; i<roiManager("count"); i++){
				roiManager("select",i);
				waitForUser("Move slection if required and click \"OK\".");
				roiManager("update");
			}
		}
		
		}else{
			if ((slices>1)&&(roiManager("count")>0)){
				for (i=Zstart; i<=Zend; i++){
					for (c=1; c<=channels; c++){
						roiManager("select",0);
						setSlice(i);
						run("Add Selection...");
					}
				}
				// Allow to move selection
				if (selectionMove==true){
					run("To ROI Manager");
					for (i=0; i<roiManager("count"); i++){
						roiManager("select",i);
						waitForUser("Move slection if required and click \"OK\".");
						roiManager("update");
					}
				}
				
			}else{print("1");
				if(roiManager("count")>0){
					for (i=start; i<=end; i++){
						roiManager("select",0);
						Stack.setDimensions(channels, slices, i); 
						roiManager("Add");
					}
				}
				
			
				// Allow to move selection
				if (selectionMove==true){
			
					for (i=1; i<roiManager("count"); i++){
						roiManager("select",i);
						waitForUser("Move slection if required and click \"OK\".");
						roiManager("update");
					}
				}
				if (frames>1)
				run("From ROI Manager");
			}
		}
		

		
		if(roiManager("count")>0){
			run("From ROI Manager");
			selectWindow("ROI Manager");
			run("Close");
		}
		
		
		answer = (getBoolean("Do you want to add more anotations?"));
	}
	if (Fl == true){
	
		run("Flatten", "stack");
	
	}
	
}