The python code in these directories is used for the final step in the creation of the emissions files.

These scripts read the pre-processed (lumped) emissions fluxes at their original resolution (0.5x0.5 degrees). The data are then regridded to N96e and written out in netCDF format with the meta data required for UKCA to interpret the numerical data correctly. These files are the emissions files that are read by the model.

* **periodic_1960/**  --  12 monthly emissions fluxes for the year 1960 (periodic)
* **timeseries_1960-2020/** -- time-varying monthly emissions fluxes from 1960 to 2020 (time series)
* **timeslice/**  -- experimental code for multi-annual time-varying emissions which were not used

