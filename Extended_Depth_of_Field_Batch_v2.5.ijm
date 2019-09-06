print("\\Clear"); 
tStart = getTime();
requires("1.42l");
print("\\Clear"); 

//run("Input/Output...", "jpeg=90 gif=-1 file=.txt use copy copy"); // set results file output paramters
// 110914 - added feature: skip an image stack if there is already and output matching that description.
// 111122 - improved parse of specific runs to read hyphenated and comma separated run names
//                - move detection of previous analyzed runs upstream of opening files to improve speed. 
//190517 - added feature: if number of threads available is >1 then EDFs of multiple channels
//			of the same image can be initialized in parallel. Number of open image windows is used to 
//			keep track of when EDFs finish.

// =======================USER DEFINED VARIABLES =====================================
		//checkBox Group doEDF
		nRows = 1;
		nColumns = 6;
		n = nRows*nColumns;
		labels1 = newArray("C0", "C1", "C2", "C3","C4","C5");
		defaults1 = newArray(true, true, true, true,false,false);
		for (i=0;i<nColumns;i++) {
			defaults1[i] = call("ij.Prefs.get", "dialogDefaults.channelChoiceC"+i, false);
		}
		labels2 = newArray("C0", "C1", "C2", "C3","C4","C5");
		defaults2 = newArray(false, false, false, false, false,false);
		nChannels = 0;
		channelChoices = newArray(6);
		
		ballSizes = newArray(6);
		Array.fill(ballSizes,-1);
		  html = "<html>"
		     +"<h2>Batch Processing EDf Help</h2>"
		     +"<font size=+1>
		     +"for composite images, do not run in batch mode<br>"
		     +"will work on this file as time allows<br>"
		     +"<font color=red>HTML</font> formatted text.<br>"
		     +"</font>";

        version = "2.2.0";
        Dialog.create("EDF Batch with Filters v" + version);
		Dialog.setInsets(10, 15, 0);
		Dialog.addMessage("Select Channels to Process");
		Dialog.setInsets(10, 35, 0);
		Dialog.addCheckboxGroup(nRows,nColumns,labels1,defaults1);
		Dialog.setInsets(10, 15, 0);		
		//Dialog.addMessage("Select Channels for background subtraction");
		Dialog.setInsets(10, 35, 0);
		//Dialog.addCheckboxGroup(nrows,ncolumns,labels1,defaults2);
		Dialog.addMessage("radius of bkgd subtraction (-1 = none):");
		Dialog.addNumber("C0:", parseInt(call("ij.Prefs.get", "dialogDefaults.ballSizeC0", "-1")),0,5," pixels");
		Dialog.addToSameRow()
		Dialog.addNumber("C1:", parseInt(call("ij.Prefs.get", "dialogDefaults.ballSizeC1", "-1")),0,5," pixels");
		
		Dialog.addNumber("C2:", parseInt(call("ij.Prefs.get", "dialogDefaults.ballSizeC2", "-1")),0,5," pixels");
		Dialog.addToSameRow()
		Dialog.addNumber("C3:", parseInt(call("ij.Prefs.get", "dialogDefaults.ballSizeC3", "-1")),0,5," pixels");
		
		Dialog.addNumber("C4:", parseInt(call("ij.Prefs.get", "dialogDefaults.ballSizeC4", "-1")),0,5," pixels");
		Dialog.addToSameRow()
		Dialog.addNumber("C5:", parseInt(call("ij.Prefs.get", "dialogDefaults.ballSizeC5", "-1")),0,5," pixels");
		
		Dialog.addCheckbox("recombine multicolor images", true);
		Dialog.addString("file types analyzed (eg tif,TIF,nd2)", call("ij.Prefs.get", "dialogDefaults.fileType", "nd2"));
		Dialog.addString("skip files containing this string", "some string");
		Dialog.addNumber("EDF accuracy (0 - low, 4 - high) ", call("ij.Prefs.get", "dialogDefaults.acXDOF", 0));
		
		nThreads = call("ij.Prefs.getThreads");
		Dialog.addMessage("Thread preferences currently set to: " + nThreads);
		Dialog.addCheckbox("Process in parallel", true);
		Dialog.addToSameRow()
		Dialog.addNumber("# threads:",  nThreads);
		
		Dialog.addCheckbox("Process subfolders ", false);
		Dialog.addCheckbox("overwrite existing images ", false);
		Dialog.addCheckbox("tidy up file extensions before running ", false);
		Dialog.addCheckbox("Notify by email when done", false);
		Dialog.addCheckbox("rolling ball before (uncheck) or after (check) EDF", false);
		Dialog.addNumber("Interval of email updates (minutes), -1 = on completion", -1);
		//Dialog.addCheckbox("run in BatchMode *** Not recommended ", false);
		Dialog.addHelp(html);
		Dialog.show();
		  
	// ====== retrieve values ============================

		for (i=0;i<nColumns;i++) {
			channelChoices[i] = Dialog.getCheckbox();
			if (channelChoices[i]==true) nChannels++; 
			call("ij.Prefs.set", "dialogDefaults.channelChoiceC"+i, channelChoices[i]);
		}
		for (i=0;i<nColumns;i++) {
			ballSizes[i] = Dialog.getNumber();
			call("ij.Prefs.set", "dialogDefaults.ballSizeC"+i, ballSizes[i]);
		}
		
		doComposite	= Dialog.getCheckbox();
		fileType	= Dialog.getString();
			call("ij.Prefs.set", "dialogDefaults.fileType", fileType);
		
		skipString = Dialog.getString();
		acXDOF = Dialog.getNumber();	
			call("ij.Prefs.set", "dialogDefaults.acXDOF", acXDOF);

		runParallel = Dialog.getCheckbox();
		nThreads = Dialog.getNumber();

		doSubFolders= Dialog.getCheckbox();
		doOverwrite = Dialog.getCheckbox();
		tidyUp = Dialog.getCheckbox();
		doSendEmail = Dialog.getCheckbox();
		bsAfterEDF = Dialog.getCheckbox();
		emailInterval = Dialog.getNumber();
		//doBatchMode = Dialog.getCheckbox();


	if (doSendEmail == true) {
		  html = "<html>"
	     +"<h2>Windows requirement for sending email via ImageJ</h2>"
    	 +"<font size=+1>
     	+"run powershell.exe as an administator"
	     +"To do this: Type powershell.exe in windows search bar"
    	 +"... right click and select Run as Administrator"
	     +"type: 'Set-ExecutionPolicy RemoteSigned' "
    	 +"</font>";
  
		// Send Emamil Module 1: Place near beginning of code. Might want as an extra option after first dialog
		Dialog.create("Email password");
		Dialog.addMessage("Security Notice: User name and password will not be stored for this operation");
		Dialog.addString("Gmail address to send email - joblo@gmail.com", "polabsfu@gmail.com",60);
		Dialog.addString("Password for sign-in", "password",60);
		Dialog.addString("Email notification to:", "dpoburko@sfu.ca",60);
		Dialog.addString("Subject:", "Extended Depth of Field Conversion Complete",70);
		Dialog.addString("Body:", "Your Extended Depth of Field job is done.",70);
		Dialog.addHelp(html);
		Dialog.show();
		usr = Dialog.getString();
		pw = Dialog.getString();
		sendTo = Dialog.getString();
		subjectText = Dialog.getString();
		bodyText = Dialog.getString();
	}

//if (doBatchMode == true) setBatchMode(true);

	channelsToProcess = newArray(nChannels);
	nChannels = channelsToProcess.length;
	counter = 0;
	//load channels to analyze into a array in "C0" notation
	ctp = " ";
	for (a=0;a<=5;a++) {
		if (channelChoices[a] == true) { 
			channelsToProcess[counter]= "C"+a;
			ctp = ctp + channelsToProcess[counter] + " " + counter + " ";
			counter++;
		}
	}	
	//print(ctp);

	// =================================================================================

	mainDir = getDirectory("Choose a Directory ");
	mainList = getFileList(mainDir);
	Array.sort(mainList);
	folderList = newArray(100);
	folderList[0] = mainDir;
	nFolders = 1;
	fileTypes = split(fileType," ");
	//Array.print(fileTypes);

	tTotal = 0;
	tSinceEmail = 0;

	// collect list of subfolders starting with main folder name
	if (doSubFolders == true ) {
		for ( i =0; i< mainList.length; i++) {
				
			if (  (endsWith(mainList[i], "/")==true)  && (indexOf(mainList[i],"EDF")==-1 ) ) {                                      // brace2 if the name is a subfolder...
				folderList[nFolders] = mainList[i];
				nFolders++;
			} else {
				print( "\\Update0: " + mainList[i] + " excluded");
			}
		}
	} else {
		nFolders =1;
	}

	//process all folders
	folderList = Array.slice(folderList,0,nFolders);
		
	for (foldersLoop =0 ; foldersLoop<folderList.length;foldersLoop++){ 

		if (foldersLoop==0) currDir = mainDir;
		if (foldersLoop>0) currDir = mainDir +folderList[foldersLoop];
		print("\\Update6: processing folder: "+currDir);
		currList = getFileList(currDir);

		//create new outputfolder if it doesn't exist
		outDirName = replace(folderList[foldersLoop],"/","");
		outPutDir = currDir + "EDF_v"+version + File.separator();
		print("\\Update7: outPutDir: "+ outPutDir);
	    if (!File.isDirectory(outPutDir)) File.makeDirectory(outPutDir);

		// generate list of files that matches positive criteria
		imgList = newArray(currList.length);
		nImgs = 0;
		for ( i =0; i< currList.length; i++) {
			for (j =0; j< fileTypes.length; j++) {
				if ( ( endsWith(currList[i], "."+fileTypes[j]) == true) && (indexOf(currList[i],skipString)==-1) ) {
							imgList[nImgs] = currList[i];
							nImgs++;
				}
				if ( ( endsWith(currList[i], ".###") == true) && (tidyUp==true) ) {
							newName = replace(currList[i],"###",fileTypes[j]);
							fr = File.rename(currDir+currList[i],currDir+newName);
							imgList[nImgs] = newName;
							nImgs++;
				}
			}
		}
		imgList = Array.slice(imgList,0,nImgs);
		imgList = Array.sort(imgList);	
		
		//process list of images from current folder
		t0 = getTime();
		
		for (imgsLoop = 0; imgsLoop < nImgs; imgsLoop++) {

				t1 = getTime();
			
				print("\\Update1: folder " +foldersLoop+1 +" img "+ imgsLoop+1 +" of " +imgList.length +" "+ imgList[imgsLoop] );

				oName = imgList[imgsLoop];
				oNameLessSuffix = substring(imgList[imgsLoop], 0, lastIndexOf(imgList[imgsLoop], "."));
				outPutName = oNameLessSuffix + "_EDF.tif";
				newpath = outPutDir + outPutName;
				oSuffix = substring(imgList[imgsLoop], lastIndexOf(imgList[imgsLoop], "."),lengthOf(imgList[imgsLoop]));
				tempSuffix = ".###";
				tempName = replace(oName, oSuffix, tempSuffix);
				skipImage = false;
				
				if ( (doOverwrite == false) && (File.exists(newpath) ) ) {
					print("\\Update2: Image exists in output directory");
					skipImage = true;
				}
				if ( File.exists(currDir + tempName) == true ) {
					print("\\Update2: Image appears to be in use by another instance of ImageJ/Fiji");
					skipImage = true;
				}

				if ( skipImage == true ) {
					//print("\\Update2: skipping image");
				} else {
						print("\\Update2: processing image");
						tfo = 0;
						open(currDir + oName);
						while (isOpen(oName) == false){
							wait(100);
							print("\\Update2: time to open file = " + (getTime()-tfo)/1000 + " s");
						}
						// rename current file to prevent other instances of Fiji or ImageJ from trying to analyze the current image
						fr = File.rename(currDir + oName,currDir + tempName);
						Stack.getDimensions(width, height, channels, slices, frames);
						print("\\Update5: stack dimensions: "+width, height, channels, slices, frames);
						nImgChannels = channels;
						imgName = getTitle();

						guessedLUTs = newArray(channels);
						reds = newArray(256);
						blues = newArray(256);
						greens = newArray(256);
		
						if (nImgChannels>1) {
		
							print("\\Update1: analyzing composite");
							run("Split Channels");
							channelsList = newArray(5);
							channelsProcessed = 0;
							tStartParallel = getTime;

							//initiate n EDFs
							imgOutNames = newArray(nImgChannels);
							edfNames = newArray(nImgChannels);
							channelIncr = minOf(nThreads, nImgChannels);
							currChannel = 1;

							while(currChannel <= nImgChannels) {
								nWindows = nImages();
								additionalWindows = 0; 
// DP to AdS: should the following line have  incrementCutOff = minOf(nImgChannels, channelIncr + currChannel-1) ? since currChannel counts as the channels being analyzed?
								incrementCutOff = minOf(nImgChannels, channelIncr + currChannel);
								 
								for (currChannel; currChannel <= incrementCutOff; currChannel++) {
									if (channelChoices[currChannel-1] == true) {
										channelName = "C"+currChannel+"-"+imgName;
										imgOutNames[currChannel-1] = channelName;
										selectWindow(imgOutNames[currChannel-1]);
								
										if ( (ballSizes[currChannel-1]!=-1) && (bsAfterEDF==false))  run("Subtract Background...", "rolling="+ballSizes[currChannel-1]+" stack");

										getLut(red, green, blue);
										reds = Array.concat(reds,red);
										greens = Array.concat(greens,green);
										blues = Array.concat(blues,blue);
										Tstart = getTime();
										channelsList[currChannel-1] = substring(channelName, 0, lastIndexOf(channelName, ".")) + "_EDF";
										additionalWindows++;
										run("Extended Depth of Field (Easy mode)...", "quality='"+acXDOF+"' topology='0' show-topology='off' show-view='off'");
											// argument quality: Speed/Quality trade-off.- 0 fast, 1 intermediate speed, 2 medium quality/speed, 3 intermediate quality, 4 high quality 
											// argument topology: Topology smoothness - 0 no smoothing of topology, 1 weak smoothing, 2 medium smoothing, 3 strong smoothing, 4 very strong smoothing
											// argument show-topology: Show the topology map - on, off
											// argument show-view: Show the 3D view - on, off
										wait(3000); // DP 190527 - This lon wait is essential to allow EDF to initiate before next is called. 
									}
								}

								expectedImages = additionalWindows + nWindows;
								//catch the output images
								wait(100); //DP changed to 100, was previously 3000 to create a delay between channels. Should not be needed anymore. 
								print("\\Update7: Waiting for " + additionalWindows + " EDFs to finish.");
								waitForProcess(expectedImages); 
							}
							wait(100);
							
							print("\\Update8: total EDF run time = " + ((getTime - tStartParallel)/1000 ) + " seconds.");
							print("\\Update7: Convert to 16-bit & Rolling Ball Subtract.");
							
							// run rolling ball and close original images

							for (currChannel = 1; currChannel <= nImgChannels; currChannel++) {
								if (channelChoices[currChannel-1] == true) {
									selectWindow(channelsList[currChannel-1]);
									setMinAndMax(0.000000000, 65535.000000000);
									run("16-bit");
									if ( (ballSizes[currChannel-1]!=-1) && (bsAfterEDF==true))  run("Subtract Background...", "rolling="+ballSizes[currChannel-1]+"");
									channelsProcessed++;
								}
								if (channelChoices[currChannel-1] == false) {
									imgOutName = "C"+currChannel+"-"+imgName;
									//selectWindow(imgOutName);
									//close();
								}

							} // channels loop

							print("\\Update7: Generating merge code.");

							tempChannelsList = newArray(channelsList.length);
							tempLutList = newArray(channelsList.length);
							nKept = 0;
							for (i=0; i<channelsList.length;i++) {
								if (channelsList[i] != 0) {
									tempChannelsList[nKept] = channelsList[i];
									tempLutList[nKept] = guessedLUTs[i];
									nKept++;
								}
							}
							
							channelsList = Array.trim(tempChannelsList,nKept);
							guessedLUTs = Array.trim(tempLutList,nKept);
							if(nKept > 1) {
								mergeCode = "";
								for (aa = 1; aa <= channelsList.length; aa++) {
									mergeCode = mergeCode + "c"+ (aa) + "=" + channelsList[aa-1] + " ";
								}
								//if (channelsList.length == 3) mergeCode = replace(mergeCode,"c3","c6");
								//if (channelsList.length == 4) mergeCode = replace(mergeCode,"c4","c6");
								mergeCode = mergeCode + "create";
								print("\\Update3: mergeCode: " + mergeCode);
								
								for (ab=0; ab<channelsList.length; ab++) {
									print("\\Update4: " + channelsList[ab] + " is open: " + isOpen(channelsList[ab]));
								}
								print("\\Update7: Merging channels.");
								run("Merge Channels...", ""+ mergeCode); 
								outPutName = oNameLessSuffix + "_EDF";
								rename(outPutName);
							} else { //only one channel kept
								outPutName = channelsList[0];
							}
							// Aims to recolor output channel to match input LUTs
							for (lut=1;lut<=guessedLUTs.length;lut++) {
								Stack.setChannel(lut);
								r = Array.slice(reds,lut*256,lut*256 + 256);
								g = Array.slice(greens,lut*256,lut*256 + 256);
								b = Array.slice(blues,lut*256,lut*256 + 256);
								//print("reds greens blues : "+reds.length +" " + greens.length+" "+blues.length);
								//print("r g b :"+r.length+g.length+b.length);
								setLut(r,g,b);
							}
							print("\\Update7: Select Merged Image.");
							selectWindow(outPutName);
							outPutName = oNameLessSuffix + "_EDF.tif";
							rename(outPutName);
							newpath = outPutDir + outPutName;
							print("\\Update7: Saving Merged Image.");
							save(newpath);
							close("*");
		
						} else { // if nImgsChannel > 1
		
							showStatus("EDF: on fldr "  +foldersLoop+1 + " img " + imgsLoop+1 +" 1Ch");
							selectWindow(imgName);
							Tstart = getTime();
							run("Extended Depth of Field (Easy mode)...", "quality='"+acXDOF+"' topology='0' show-topology='off' show-view='off'");
									// argument quality: Speed/Quality trade-off.- 0 fast, 1 intermediate speed, 2 medium quality/speed, 3 intermediate quality, 4 high quality 
									// argument topology: Topology smoothness - 0 no smoothing of topology, 1 weak smoothing, 2 medium smoothing, 3 strong smoothing, 4 very strong smoothing
									// argument show-topology: Show the topology map - on, off
									// argument show-view: Show the 3D view - on, off
							while (isOpen(oNameLessSuffix + "_EDF") == 0) {    //checks if EDF has finished
									wait(100);
							}
							
							setMinAndMax(0.000000000, 65535.000000000);
							run("16-bit");
							Tend = getTime();
							print("\\Update8: EDF run time = " + ((Tend - Tstart)/1000 ) + " seconds.");
							
							if (ballSizes[0] != -1) run("Subtract Background...", "rolling="+ballSizes[0]+""); //FIX ME: no variable named ballSize only an array
							outPutName = oNameLessSuffix + ".tif";
							selectWindow(oNameLessSuffix + "_EDF");
							rename(outPutName);
							newpath = outPutDir + outPutName;
							save(newpath);
							close();
							selectWindow(imgName);
							close();	
						}

 				// rename current file back to its original name
				fr = File.rename(currDir + tempName, currDir + oName);


				//Create progress bar in log
				lapTime = (getTime() - t1)/1000;
				
				tTotal = tTotal + lapTime;
				t1 = getTime();
				LapsLeft = (nImgs-1) - imgsLoop;
				tLeft = (  (t1-t0) / (imgsLoop+1) ) *  ((nImgs-1) - imgsLoop)  / 1000 ;
				progress = ( imgsLoop + 1)/nImgs ;
				pctDoneLength = 40;
				pctDone = progress*pctDoneLength;
				pctDoneString = "";
				pctLeftString = "";
				for(bb = 0; bb<pctDoneLength;bb++) {
					pctDoneString = pctDoneString + "|";
					pctLeftString = pctLeftString + ".";
				}
				pctDoneString = substring(pctDoneString ,0,pctDone);
				pctLeftString = substring(pctLeftString ,0,pctDoneLength - pctDone);
				print ("\\Update0: image list: " + pctDoneString + pctLeftString + " " +  (imgsLoop+1) + " of " + nImgs + " lap time: " + d2s(lapTime,3) + " s, loop time: " + d2s(tLeft/60,1) + " min for folder " + foldersLoop+1 + " of " +folderList.length );


			if (emailInterval >0){
				if( (tTotal/60 - tSinceEmail/60) > emailInterval) {
					sb = "EDF update ~"+ d2s(tLeft/3600,1) + "h remaining" ;
					bd = "" + pctDoneString + pctLeftString + " " +  (imgsLoop+1) + " of " + nImgs + " lap time: " + d2s(lapTime,3) + " s, loop time: " + d2s(tLeft/60,1) + " min for folder " + foldersLoop+1 + " of " +folderList.length ;
					sendEmail(sb,bd);
					tSinceEmail = tTotal;
				}
				
			}


			} // close if exists 
		} //close images loop 
	} //close foldersLoop


setBatchMode("exit and display"); 
showStatus("Batch analysis complete");

	if (doSendEmail == true) {
		sendEmail(subjectText,bodyText);
	}




// ============================================================================================
// ============== FUNCTIONS ===================================================================
// ============================================================================================
function sendEmail(sb, bd) {
		// Send Email Module 2: Place at end of code once all other operations are complete
		pShellString = "$EmailFrom = \“"+usr+"\”";
		//pShellString = pShellString+"\n$EmailTo = \“dpoburko@sfu.ca\”";
		pShellString = pShellString+"\n$EmailTo = \“"+sendTo+"\”";
		pShellString = pShellString+"\n$Subject = \“"+sb+"\”";
		pShellString = pShellString+"\n$Body = \“"+bd+"\”";
		pShellString = pShellString+"\n$SMTPServer = \“smtp.gmail.com\”";
		pShellString = pShellString+"\n$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587)";
		pShellString = pShellString+"\n$SMTPClient.EnableSsl = $true";
		pShellString = pShellString+"\n$SMTPClient.Credentials = New-Object System.Net.NetworkCredential(\“"+usr+"\”, \“"+pw+"\”)";
		pShellString = pShellString+"\n$SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)";
		//print(pShellString);
		path =getDirectory("imagej") + "powerShellEmail.ps1";
		fs = File.saveString(pShellString, path);
		exec("cmd", "/c", "start", "powershell.exe", path);
		fd = File.delete(path);

	
}

// *****************************************************************************************************************************************************************************************

function specificRuns(subDirName, runsList) {
	for (a=0; a<runsList.length; a++) {
			if (indexOf(subDirName,runsList[a])!=-1) return true;		
		}
		return false;
}
// *****************************************************************************************************************************************************************************************


// *****************************************************************************************************************************************************************************************
// ****************** FUNCTIONS *****************************************************************************************************************************************************
// *****************************************************************************************************************************************************************************************


function doEDF(currName, acXDOF) {  // Isolate and measure puncta ***************************************************************************************************************************

	selectWindow(currName);
	
	//run EDF,wait, close original image, save individual or merge all channels
	showStatus("EDF: on fldr "  +foldersLoop+1 + " img " + imgsLoop+1 +" Ch "+ currChannel );
	Tstart = getTime();
	run("Extended Depth of Field (Easy mode)...", "quality='"+acXDOF+"' topology='0' show-topology='off' show-view='off'");
			// argument quality: Speed/Quality trade-off.- 0 fast, 1 intermediate speed, 2 medium quality/speed, 3 intermediate quality, 4 high quality 
			// argument topology: Topology smoothness - 0 no smoothing of topology, 1 weak smoothing, 2 medium smoothing, 3 strong smoothing, 4 very strong smoothing
			// argument show-topology: Show the topology map - on, off
			// argument show-view: Show the 3D view - on, off
	edfStart = getTime();
	while (isOpen("Output") == 0) {    //checks if EDF has finished
		tEDF = " " + ((getTime() - edfStart)/1000 ) + " s"
		showStatus("EDF: on fldr "  +foldersLoop+1 + " img " + imgsLoop+1 +" Ch "+ currChannel + tEDF );
			print("\\Update8: elapsed EDF time = " + ((getTime() - edfStart)/1000 ) + " seconds.");
			wait(100);
	}
	setMinAndMax(0.000000000, 65535.000000000);
	run("16-bit");
	Tend = getTime();
	print("\\Update8: EDF run time = " + ((Tend - Tstart)/1000 ) + " seconds.");

					 
	//call("java.lang.System.gc");  // clear memory usage
 } // ******************* close function puncta()  *******************************************************************************************************************

 function MIP(currName,subDir) {  // Isolate and measure puncta ***************************************************************************************************************************
// *****************************************************************************************************************************************************************************************

	selectWindow(currName);
	stkSize = nSlices();
	Tstart = getTime();
	run("Z Project...", "start=1 stop="+stkSize+" projection=[Max Intensity]");
	while (isOpen("MAX_"+currName) == 0) {    //checks if EDF has finished
		wait(20);
	}

	Tend = getTime();
		print("MIP run time = " + ((Tend - Tstart)/1000 ) + " seconds.");

	selectWindow("MAX_"+currName);
	analyzedName = currName + "_MAX.tif";
	rename(analyzedName);
	newpath = subDir + analyzedName;
	save(newpath);
	print("saved " + currName + "_MAX.tif");
	close();
} // ******************* close function puncta()  *******************************************************************************************************************

// *****************************************************************************************************************************************************************************************
function list(a) {
	for (i=0; i<a.length; i++)
		print(a[i]);
	print("");
} // close function list(a) **********************************************************************************************************************************************

// *****************************************************************************************************************************************************************************************
function parseStringList(a) { 
	a = replace(a," ","");
	stringList = split(a,",");

	for (l = 0; l<stringList.length;l++) {
		//print(stringList[l]);
	}

	nToAnalyze = 0;
	tempList = newArray(50);

	for (j=0;j<stringList.length;j++) {
		if (indexOf(stringList[j],"-")!=-1) {
			unicodeIndex0 = charCodeAt(stringList[j],0);
			afterHyphen = 1+ indexOf(stringList[j], "-");
			unicodeIndex1 = charCodeAt(stringList[j],afterHyphen);
			tempCharArray = newArray(1 + unicodeIndex1 - unicodeIndex0);

			for (k=	0; k<tempCharArray.length;k++) {
				tempList[nToAnalyze] = fromCharCode(unicodeIndex0 + k) + "0";
				nToAnalyze ++;			
			}	
		} else {
			tempList[nToAnalyze] = stringList[j];
			nToAnalyze ++;
		}
	}
	stringList = newArray(nToAnalyze);
	for (l = 0; l<stringList.length;l++) {
		stringList[l] = tempList[l];
		//print(stringList[l]);
	}
	return stringList;
} // close function parseStringList(a) **********************************************************************************************************************************************


// **********************************************************************************************************************************************************************************
//Function waits for the expected number of images to open before returning
function waitForProcess(expectedImages) {
	
	edfT0 = getTime();
	while(nImages() < expectedImages) {
		wait(100);
		print("\\Update8: total EDF run time = " +d2s( (getTime-edfT0)/1000,1)+ " s");
	} //else return
} // close function waitForProcess()*************************************************************************************************************************************************

tEnd = getTime();
timeElapsed = (tEnd - tStart)/60000;
setBatchMode(false); 
print("macro took " + timeElapsed + " min"); 
