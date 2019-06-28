# ExtendedDepthofField
Modification of EPFL's EDF plugin for ImageJ. This version renames the output image as input_EDF.ext instead of Output.ext. This allows a macro to call multiple instances of the EDF plugin and watch for specific output images. Processing time is greatly reduced for multi-color image stacks, provided that the processing CPU has at least one thread available per image channel. 

## Reference 
B. Forster, D. Van De Ville, J. Berent, D. Sage, M. Unser. Complex Wavelets for Extended Depth-of-Field: A New Method for the Fusion of Multichannel Microscopy Images, Microscopy Research and Techniques,65(1-2), pp. 33-42, September 2004.
