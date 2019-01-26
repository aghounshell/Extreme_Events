# Extreme weather events modulate processing and export of dissolved organic carbon in the Neuse River Estuary, NC

### Authors: Alexandria G. Hounshell, Jacob C. Rudolph, Bryce R. Van Dam, Nathan S. Hall, Christopher L. Osburn, and Hans W. Paerl

#### For any questions or comments, please contact the corresponding author (Alexandria G. Hounshell) at ahounshell10(at)gmail.com

#### Information about this repository:

This is the data and code repository for the manuscript "Extreme weather events modulate processing and export of dissolved organic carbon in the Neuse River Estuary, NC" prepared for Estuarine, Coastal and Shelf Science by Alexandria G. Hounshell, Jacob C. Rudolph, Bryce R. Van Dam, Nathan S. Hall, Christopher L. Osburn, and Hans W. Paerl

Link to manuscript

#### File description:

The associated files have all the necessary equations, explanations, code, and data needed to generate an estuarine box model as described in the manuscript including a salinity balance to calculate estuarine circulation as well as code to calculate a dissolved organic carbon and CDOM absorbance (350 nm) source or sink term for the estuary.

Start by reveiwing the BoxModel_Equations.pdf file. This contains information on how the box model and associated equations were derived. This document, along with the supplementary information for the manuscript as linked above, should contain all the visuals, equations, and explanations for deriving the various box models.

The Data file contains all data needed to generate three box models: 1) Salinity box model, 2) Dissolved organic carbon box model, and 3) CDOM absorbance model. The data will be pulled in by Matlab as described in the associated codes.

The Code file contains all necessary Matlab codes to develop the three box models as described above: 1) SalBoxModel_Final.m, 2) DOC_BoxModel_Final.m and 3) a350_BoxModel_Final.m. Start with the SalBoxModel_Final.m to calculate estuarine circulation. The results from this will then be used in the subsequent box models (DOC and a350). The results from the SalBoxModel_Final.m are contained as ForOCBoxModel.mat which will be used as an input to the subsequent DOC and a350 box models.
