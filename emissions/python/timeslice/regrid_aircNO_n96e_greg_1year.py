#!/usr/bin/env python
##############################################################################################
#
#
#  regrid_emissions_N96e.py
#
#
#  Requirements:
#  Iris 1.10, cf_units, numpy
#
#
#  This Python script has been written by N.L. Abraham as part of the UKCA Tutorials:
#   http://www.ukca.ac.uk/wiki/index.php/UKCA_Chemistry_and_Aerosol_Tutorials_at_vn10.4
#
#  Copyright (C) 2015  University of Cambridge
#
#  This is free software: you can redistribute it and/or modify it under the
#  terms of the GNU Lesser General Public License as published by the Free Software
#  Foundation, either version 3 of the License, or (at your option) any later
#  version.
#
#  It is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#  PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.
#
#  You find a copy of the GNU Lesser General Public License at <http://www.gnu.org/licenses/>.
#
#  Written by N. Luke Abraham 2016-10-20 <nla27@cam.ac.uk> 
#
#
##############################################################################################

# preamble
import iris
import cf_units
import numpy

# --- CHANGE THINGS BELOW THIS LINE TO WORK WITH YOUR FILES ETC. ---

# name of file containing an ENDGame grid, e.g. your model output
# NOTE: all the fields in the file should be on the same horizontal
#       grid, as the field used MAY NOT be the first in order of STASH
#grid_file='/group_workspaces/jasmin2/ukca/vol1/mkoehler/um/archer/ag542/apm.pp/ag542a.pm1988dec'
#
# name of emissions file
emissions_file='/group_workspaces/jasmin2/ukca/vol1/mkoehler/emissions/ACCMIP-MACCity_anthrop_1960-2020/sectors/NOx/n96e/MACCity_aircraft_NO_2000_n96l85.nc'
#
# STASH code emissions are associated with
#  301-320: surface
#  m01s00i303: CO surface emissions
#
#  321-340: full atmosphere
#
stash='m01s00i340'

# --- BELOW THIS LINE, NOTHING SHOULD NEED TO BE CHANGED ---

species_name='NO_aircrft'

# this is the grid we want to regrid to, e.g. N96 ENDGame
#grd=iris.load(grid_file)[0]
#grd.coord(axis='x').guess_bounds()
#grd.coord(axis='y').guess_bounds()

# This is the original data
#ems=iris.load_cube(emissions_file)
ocube=iris.load_cube(emissions_file)

# make intersection between 0 and 360 longitude to ensure that 
# the data is regridded correctly
#nems = ems.intersection(longitude=(0, 360))

# make sure that we use the same coordinate system, otherwise regrid won't work
#nems.coord(axis='x').coord_system=grd.coord_system()
#nems.coord(axis='y').coord_system=grd.coord_system()

# now guess the bounds of the new grid prior to regridding
#nems.coord(axis='x').guess_bounds()
#nems.coord(axis='y').guess_bounds()

# now regrid
#ocube=nems.regrid(grd,iris.analysis.AreaWeighted())

# now add correct attributes and names to netCDF file
ocube.var_name='emissions_NO_aircrft'
ocube.long_name='NOx aircraft emissions'
ocube.units=cf_units.Unit('kg m-2 s-1')
ocube.attributes['vertical_scaling']='all_levels'
ocube.attributes['um_stash_source']=stash
ocube.attributes['tracer_name']='NO_aircrft'

# global attributes, so don't set in local_keys
# NOTE: all these should be strings, including the numbers!
# basic emissions type
ocube.attributes['emission_type']='1' # time series
ocube.attributes['update_type']='1'   # same as above
ocube.attributes['update_freq_in_hours']='120' # i.e. 5 days
ocube.attributes['um_version']='10.4' # UM version
ocube.attributes['source']='MACCity_aircraft_NO_1960-2020_n96l85.nc'
ocube.attributes['data_version']='Beta release'

# rename and set time coord - mid-month from 1960-Jan to 2020-Dec
# this bit is annoyingly fiddly
ocube.coord(axis='t').var_name='time'
ocube.coord(axis='t').standard_name='time'
ocube.coords(axis='t')[0].units=cf_units.Unit('days since 1960-01-01 00:00:00', calendar='gregorian')
ocube.coord(axis='t').points=numpy.array([15.5, 45.5, 75.5, 106, 136.5, 167, 197.5, 
    228.5, 259, 289.5, 320, 350.5])

# make z-direction.  -- MOK we won't need this for aircraft emissions?
#zdims=iris.coords.DimCoord(numpy.array([0]),standard_name = 'model_level_number',
#                           units='1',attributes={'positive':'up'})
#ocube.add_aux_coord(zdims)
#ocube=iris.util.new_axis(ocube, zdims)
# now transpose cube to put Z 2nd
#ocube.transpose([1,0,2,3])

# guess bounds of x and y dimension
ocube.coord(axis='x').guess_bounds()
ocube.coord(axis='y').guess_bounds()

# make coordinates 64-bit
ocube.coord(axis='x').points=ocube.coord(axis='x').points.astype(dtype='float64')
ocube.coord(axis='y').points=ocube.coord(axis='y').points.astype(dtype='float64')
# MOK -- uncomment the following line:
ocube.coord(axis='z').points=ocube.coord(axis='z').points.astype(dtype='float64') # integer
ocube.coord(axis='t').points=ocube.coord(axis='t').points.astype(dtype='float64')
# for some reason, longitude_bounds are double, but latitude_bounds are float
ocube.coord('latitude').bounds=ocube.coord('latitude').bounds.astype(dtype='float64')


# add forecast_period & forecast_reference_time
# forecast_reference_time
frt=numpy.array([15.5, 45.5, 75.5, 106, 136.5, 167, 197.5, 
    228.5, 259, 289.5, 320, 350.5],dtype='float64')
frt_dims=iris.coords.AuxCoord(frt,standard_name = 'forecast_reference_time',
                           units=cf_units.Unit('days since 1960-01-01 00:00:00', calendar='gregorian'))
ocube.add_aux_coord(frt_dims,data_dims=0)
ocube.coord('forecast_reference_time').guess_bounds()
# forecast_period
fp=numpy.array([-360],dtype='float64')
fp_dims=iris.coords.AuxCoord(fp,standard_name = 'forecast_period',
                           units=cf_units.Unit('hours'),bounds=numpy.array([-720,0],dtype='float64'))
ocube.add_aux_coord(fp_dims,data_dims=None)

# add-in cell_methods
ocube.cell_methods = [iris.coords.CellMethod('mean', 'time')]
# set _FillValue
fillval=1e+20
ocube.data = numpy.ma.array(data=ocube.data, fill_value=fillval, dtype='float32')

# output file name, based on species
outpath='ukca_emiss_'+species_name+'.nc'
# don't want time to be cattable, as is a periodic emissions file
iris.FUTURE.netcdf_no_unlimited=False
# annoying hack to set a missing_value attribute as well as a _FillValue attribute
dict.__setitem__(ocube.attributes, 'missing_value', fillval)
# now write-out to netCDF
saver = iris.fileformats.netcdf.Saver(filename=outpath, netcdf_format='NETCDF4_CLASSIC')
saver.update_global_attributes(Conventions=iris.fileformats.netcdf.CF_CONVENTIONS_VERSION)
saver.write(ocube, local_keys=['vertical_scaling', 'missing_value','um_stash_source','tracer_name'])

# end of script
