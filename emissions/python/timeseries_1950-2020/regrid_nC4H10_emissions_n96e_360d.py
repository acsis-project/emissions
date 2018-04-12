#!/usr/bin/env python
##############################################################################################
#
#
#  regrid_emissions_N96e.py
#
#
#  Requirements:
#  Iris 1.10, time, cf_units, numpy
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
#  Modified by Marcus Koehler 2018-01-05 <mok21@cam.ac.uk>
#
#
##############################################################################################

# preamble
import time
import iris
import cf_units
import numpy

# --- CHANGE THINGS BELOW THIS LINE TO WORK WITH YOUR FILES ETC. ---

# name of file containing an ENDGame grid, e.g. your model output
# NOTE: all the fields in the file should be on the same horizontal
#       grid, as the field used MAY NOT be the first in order of STASH
grid_file='/group_workspaces/jasmin2/ukca/vol1/mkoehler/um/archer/ag542/apm.pp/ag542a.pm1988dec'
#
# name of emissions file 
# NOTE: We use the fluxes from the Gregorian calendar file also for the 360_day emission files
emissions_file='/group_workspaces/jasmin2/ukca/vol1/mkoehler/emissions/OXBUDS/0.5x0.5/v4/combined_sources_n-butane_1950-2020_v4.nc'

# --- BELOW THIS LINE, NOTHING SHOULD NEED TO BE CHANGED ---

species_name='n-C4H10'

# this is the grid we want to regrid to, e.g. N96 ENDGame
grd=iris.load(grid_file)[0]
grd.coord(axis='x').guess_bounds()
grd.coord(axis='y').guess_bounds()

# This is the original data
ems=iris.load_cube(emissions_file)

# make intersection between 0 and 360 longitude to ensure that 
# the data is regridded correctly
nems = ems.intersection(longitude=(0, 360))

# make sure that we use the same coordinate system, otherwise regrid won't work
nems.coord(axis='x').coord_system=grd.coord_system()
nems.coord(axis='y').coord_system=grd.coord_system()

# now guess the bounds of the new grid prior to regridding
nems.coord(axis='x').guess_bounds()
nems.coord(axis='y').guess_bounds()

# now regrid
ocube=nems.regrid(grd,iris.analysis.AreaWeighted())

# now add correct attributes and names to netCDF file
ocube.var_name='emissions_'+str.strip(species_name)
ocube.long_name='n-butane surface emissions'
ocube.standard_name='tendency_of_atmosphere_mass_content_of_butane_due_to_emission'
ocube.units=cf_units.Unit('kg m-2 s-1')
ocube.attributes['vertical_scaling']='surface'
ocube.attributes['tracer_name']=str.strip(species_name)

# global attributes, so don't set in local_keys
# NOTE: all these should be strings, including the numbers!
# basic emissions type
ocube.attributes['emission_type']='1' # time series
ocube.attributes['update_type']='1'   # same as above
ocube.attributes['update_freq_in_hours']='120' # i.e. 5 days
ocube.attributes['um_version']='10.6' # UM version
ocube.attributes['source']='combined_sources_n-butane_1950-2020_v4.nc'
ocube.attributes['title']='Time-varying monthly surface emissions of n-butane from 1950 to 2020.'
ocube.attributes['File_version']='v4'
ocube.attributes['File_creation_date']=time.ctime(time.time())
ocube.attributes['grid']='regular 1.875 x 1.25 degree longitude-latitude grid (N96e)'
ocube.attributes['history']=time.ctime(time.time())+': '+__file__+' \n'+ocube.attributes['history']
ocube.attributes['institution']='Centre for Atmospheric Science, Department of Chemistry, University of Cambridge, U.K.'
ocube.attributes['reference']='Granier et al., Clim. Change, 2011; Lamarque et al., Atmos. Chem. Phys., 2010; Helmig et al., Atmos. Environ., 2014.'

del ocube.attributes['file_creation_date']
del ocube.attributes['description']

# rename and set time coord - mid-month from 1950-Jan to 2020-Dec
# this bit is annoyingly fiddly
ocube.coord(axis='t').var_name='time'
ocube.coord(axis='t').standard_name='time'
ocube.coords(axis='t')[0].units=cf_units.Unit('days since 1950-01-01 00:00:00', calendar='360_day')
ocube.coord(axis='t').points=numpy.array([
    15, 45, 75, 105, 135, 165, 195, 225, 255, 285, 315, 345, 375, 405, 
    435, 465, 495, 525, 555, 585, 615, 645, 675, 705, 735, 765, 795, 825, 
    855, 885, 915, 945, 975, 1005, 1035, 1065, 1095, 1125, 1155, 1185, 1215, 
    1245, 1275, 1305, 1335, 1365, 1395, 1425, 1455, 1485, 1515, 1545, 1575, 
    1605, 1635, 1665, 1695, 1725, 1755, 1785, 1815, 1845, 1875, 1905, 1935, 
    1965, 1995, 2025, 2055, 2085, 2115, 2145, 2175, 2205, 2235, 2265, 2295, 
    2325, 2355, 2385, 2415, 2445, 2475, 2505, 2535, 2565, 2595, 2625, 2655, 
    2685, 2715, 2745, 2775, 2805, 2835, 2865, 2895, 2925, 2955, 2985, 3015, 
    3045, 3075, 3105, 3135, 3165, 3195, 3225, 3255, 3285, 3315, 3345, 3375, 
    3405, 3435, 3465, 3495, 3525, 3555, 3585, 3615, 3645, 3675, 3705, 3735, 
    3765, 3795, 3825, 3855, 3885, 3915, 3945, 3975, 4005, 4035, 4065, 4095, 
    4125, 4155, 4185, 4215, 4245, 4275, 4305, 4335, 4365, 4395, 4425, 4455, 
    4485, 4515, 4545, 4575, 4605, 4635, 4665, 4695, 4725, 4755, 4785, 4815, 
    4845, 4875, 4905, 4935, 4965, 4995, 5025, 5055, 5085, 5115, 5145, 5175, 
    5205, 5235, 5265, 5295, 5325, 5355, 5385, 5415, 5445, 5475, 5505, 5535, 
    5565, 5595, 5625, 5655, 5685, 5715, 5745, 5775, 5805, 5835, 5865, 5895, 
    5925, 5955, 5985, 6015, 6045, 6075, 6105, 6135, 6165, 6195, 6225, 6255, 
    6285, 6315, 6345, 6375, 6405, 6435, 6465, 6495, 6525, 6555, 6585, 6615, 
    6645, 6675, 6705, 6735, 6765, 6795, 6825, 6855, 6885, 6915, 6945, 6975, 
    7005, 7035, 7065, 7095, 7125, 7155, 7185, 7215, 7245, 7275, 7305, 7335, 
    7365, 7395, 7425, 7455, 7485, 7515, 7545, 7575, 7605, 7635, 7665, 7695, 
    7725, 7755, 7785, 7815, 7845, 7875, 7905, 7935, 7965, 7995, 8025, 8055, 
    8085, 8115, 8145, 8175, 8205, 8235, 8265, 8295, 8325, 8355, 8385, 8415, 
    8445, 8475, 8505, 8535, 8565, 8595, 8625, 8655, 8685, 8715, 8745, 8775, 
    8805, 8835, 8865, 8895, 8925, 8955, 8985, 9015, 9045, 9075, 9105, 9135, 
    9165, 9195, 9225, 9255, 9285, 9315, 9345, 9375, 9405, 9435, 9465, 9495, 
    9525, 9555, 9585, 9615, 9645, 9675, 9705, 9735, 9765, 9795, 9825, 9855, 
    9885, 9915, 9945, 9975, 10005, 10035, 10065, 10095, 10125, 10155, 10185, 
    10215, 10245, 10275, 10305, 10335, 10365, 10395, 10425, 10455, 10485, 
    10515, 10545, 10575, 10605, 10635, 10665, 10695, 10725, 10755, 10785, 
    10815, 10845, 10875, 10905, 10935, 10965, 10995, 11025, 11055, 11085, 
    11115, 11145, 11175, 11205, 11235, 11265, 11295, 11325, 11355, 11385, 
    11415, 11445, 11475, 11505, 11535, 11565, 11595, 11625, 11655, 11685, 
    11715, 11745, 11775, 11805, 11835, 11865, 11895, 11925, 11955, 11985, 
    12015, 12045, 12075, 12105, 12135, 12165, 12195, 12225, 12255, 12285, 
    12315, 12345, 12375, 12405, 12435, 12465, 12495, 12525, 12555, 12585, 
    12615, 12645, 12675, 12705, 12735, 12765, 12795, 12825, 12855, 12885, 
    12915, 12945, 12975, 13005, 13035, 13065, 13095, 13125, 13155, 13185, 
    13215, 13245, 13275, 13305, 13335, 13365, 13395, 13425, 13455, 13485, 
    13515, 13545, 13575, 13605, 13635, 13665, 13695, 13725, 13755, 13785, 
    13815, 13845, 13875, 13905, 13935, 13965, 13995, 14025, 14055, 14085, 
    14115, 14145, 14175, 14205, 14235, 14265, 14295, 14325, 14355, 14385, 
    14415, 14445, 14475, 14505, 14535, 14565, 14595, 14625, 14655, 14685, 
    14715, 14745, 14775, 14805, 14835, 14865, 14895, 14925, 14955, 14985, 
    15015, 15045, 15075, 15105, 15135, 15165, 15195, 15225, 15255, 15285, 
    15315, 15345, 15375, 15405, 15435, 15465, 15495, 15525, 15555, 15585, 
    15615, 15645, 15675, 15705, 15735, 15765, 15795, 15825, 15855, 15885, 
    15915, 15945, 15975, 16005, 16035, 16065, 16095, 16125, 16155, 16185, 
    16215, 16245, 16275, 16305, 16335, 16365, 16395, 16425, 16455, 16485, 
    16515, 16545, 16575, 16605, 16635, 16665, 16695, 16725, 16755, 16785, 
    16815, 16845, 16875, 16905, 16935, 16965, 16995, 17025, 17055, 17085, 
    17115, 17145, 17175, 17205, 17235, 17265, 17295, 17325, 17355, 17385, 
    17415, 17445, 17475, 17505, 17535, 17565, 17595, 17625, 17655, 17685, 
    17715, 17745, 17775, 17805, 17835, 17865, 17895, 17925, 17955, 17985, 
    18015, 18045, 18075, 18105, 18135, 18165, 18195, 18225, 18255, 18285, 
    18315, 18345, 18375, 18405, 18435, 18465, 18495, 18525, 18555, 18585, 
    18615, 18645, 18675, 18705, 18735, 18765, 18795, 18825, 18855, 18885, 
    18915, 18945, 18975, 19005, 19035, 19065, 19095, 19125, 19155, 19185, 
    19215, 19245, 19275, 19305, 19335, 19365, 19395, 19425, 19455, 19485, 
    19515, 19545, 19575, 19605, 19635, 19665, 19695, 19725, 19755, 19785, 
    19815, 19845, 19875, 19905, 19935, 19965, 19995, 20025, 20055, 20085, 
    20115, 20145, 20175, 20205, 20235, 20265, 20295, 20325, 20355, 20385, 
    20415, 20445, 20475, 20505, 20535, 20565, 20595, 20625, 20655, 20685, 
    20715, 20745, 20775, 20805, 20835, 20865, 20895, 20925, 20955, 20985, 
    21015, 21045, 21075, 21105, 21135, 21165, 21195, 21225, 21255, 21285, 
    21315, 21345, 21375, 21405, 21435, 21465, 21495, 21525, 21555, 21585, 
    21615, 21645, 21675, 21705, 21735, 21765, 21795, 21825, 21855, 21885, 
    21915, 21945, 21975, 22005, 22035, 22065, 22095, 22125, 22155, 22185, 
    22215, 22245, 22275, 22305, 22335, 22365, 22395, 22425, 22455, 22485, 
    22515, 22545, 22575, 22605, 22635, 22665, 22695, 22725, 22755, 22785, 
    22815, 22845, 22875, 22905, 22935, 22965, 22995, 23025, 23055, 23085, 
    23115, 23145, 23175, 23205, 23235, 23265, 23295, 23325, 23355, 23385, 
    23415, 23445, 23475, 23505, 23535, 23565, 23595, 23625, 23655, 23685, 
    23715, 23745, 23775, 23805, 23835, 23865, 23895, 23925, 23955, 23985, 
    24015, 24045, 24075, 24105, 24135, 24165, 24195, 24225, 24255, 24285, 
    24315, 24345, 24375, 24405, 24435, 24465, 24495, 24525, 24555, 24585, 
    24615, 24645, 24675, 24705, 24735, 24765, 24795, 24825, 24855, 24885, 
    24915, 24945, 24975, 25005, 25035, 25065, 25095, 25125, 25155, 25185, 
    25215, 25245, 25275, 25305, 25335, 25365, 25395, 25425, 25455, 25485, 
    25515, 25545 ])

# make z-direction.
zdims=iris.coords.DimCoord(numpy.array([0]),standard_name = 'model_level_number',
                           units='1',attributes={'positive':'up'})
ocube.add_aux_coord(zdims)
ocube=iris.util.new_axis(ocube, zdims)
# now transpose cube to put Z 2nd
ocube.transpose([1,0,2,3])

# make coordinates 64-bit
ocube.coord(axis='x').points=ocube.coord(axis='x').points.astype(dtype='float64')
ocube.coord(axis='y').points=ocube.coord(axis='y').points.astype(dtype='float64')
#ocube.coord(axis='z').points=ocube.coord(axis='z').points.astype(dtype='float64') # integer
ocube.coord(axis='t').points=ocube.coord(axis='t').points.astype(dtype='float64')
# for some reason, longitude_bounds are double, but latitude_bounds are float
ocube.coord('latitude').bounds=ocube.coord('latitude').bounds.astype(dtype='float64')


# add forecast_period & forecast_reference_time
# forecast_reference_time
frt=numpy.array([
    15, 45, 75, 105, 135, 165, 195, 225, 255, 285, 315, 345, 375, 405, 
    435, 465, 495, 525, 555, 585, 615, 645, 675, 705, 735, 765, 795, 825, 
    855, 885, 915, 945, 975, 1005, 1035, 1065, 1095, 1125, 1155, 1185, 1215, 
    1245, 1275, 1305, 1335, 1365, 1395, 1425, 1455, 1485, 1515, 1545, 1575, 
    1605, 1635, 1665, 1695, 1725, 1755, 1785, 1815, 1845, 1875, 1905, 1935, 
    1965, 1995, 2025, 2055, 2085, 2115, 2145, 2175, 2205, 2235, 2265, 2295, 
    2325, 2355, 2385, 2415, 2445, 2475, 2505, 2535, 2565, 2595, 2625, 2655, 
    2685, 2715, 2745, 2775, 2805, 2835, 2865, 2895, 2925, 2955, 2985, 3015, 
    3045, 3075, 3105, 3135, 3165, 3195, 3225, 3255, 3285, 3315, 3345, 3375, 
    3405, 3435, 3465, 3495, 3525, 3555, 3585, 3615, 3645, 3675, 3705, 3735, 
    3765, 3795, 3825, 3855, 3885, 3915, 3945, 3975, 4005, 4035, 4065, 4095, 
    4125, 4155, 4185, 4215, 4245, 4275, 4305, 4335, 4365, 4395, 4425, 4455, 
    4485, 4515, 4545, 4575, 4605, 4635, 4665, 4695, 4725, 4755, 4785, 4815, 
    4845, 4875, 4905, 4935, 4965, 4995, 5025, 5055, 5085, 5115, 5145, 5175, 
    5205, 5235, 5265, 5295, 5325, 5355, 5385, 5415, 5445, 5475, 5505, 5535, 
    5565, 5595, 5625, 5655, 5685, 5715, 5745, 5775, 5805, 5835, 5865, 5895, 
    5925, 5955, 5985, 6015, 6045, 6075, 6105, 6135, 6165, 6195, 6225, 6255, 
    6285, 6315, 6345, 6375, 6405, 6435, 6465, 6495, 6525, 6555, 6585, 6615, 
    6645, 6675, 6705, 6735, 6765, 6795, 6825, 6855, 6885, 6915, 6945, 6975, 
    7005, 7035, 7065, 7095, 7125, 7155, 7185, 7215, 7245, 7275, 7305, 7335, 
    7365, 7395, 7425, 7455, 7485, 7515, 7545, 7575, 7605, 7635, 7665, 7695, 
    7725, 7755, 7785, 7815, 7845, 7875, 7905, 7935, 7965, 7995, 8025, 8055, 
    8085, 8115, 8145, 8175, 8205, 8235, 8265, 8295, 8325, 8355, 8385, 8415, 
    8445, 8475, 8505, 8535, 8565, 8595, 8625, 8655, 8685, 8715, 8745, 8775, 
    8805, 8835, 8865, 8895, 8925, 8955, 8985, 9015, 9045, 9075, 9105, 9135, 
    9165, 9195, 9225, 9255, 9285, 9315, 9345, 9375, 9405, 9435, 9465, 9495, 
    9525, 9555, 9585, 9615, 9645, 9675, 9705, 9735, 9765, 9795, 9825, 9855, 
    9885, 9915, 9945, 9975, 10005, 10035, 10065, 10095, 10125, 10155, 10185, 
    10215, 10245, 10275, 10305, 10335, 10365, 10395, 10425, 10455, 10485, 
    10515, 10545, 10575, 10605, 10635, 10665, 10695, 10725, 10755, 10785, 
    10815, 10845, 10875, 10905, 10935, 10965, 10995, 11025, 11055, 11085, 
    11115, 11145, 11175, 11205, 11235, 11265, 11295, 11325, 11355, 11385, 
    11415, 11445, 11475, 11505, 11535, 11565, 11595, 11625, 11655, 11685, 
    11715, 11745, 11775, 11805, 11835, 11865, 11895, 11925, 11955, 11985, 
    12015, 12045, 12075, 12105, 12135, 12165, 12195, 12225, 12255, 12285, 
    12315, 12345, 12375, 12405, 12435, 12465, 12495, 12525, 12555, 12585, 
    12615, 12645, 12675, 12705, 12735, 12765, 12795, 12825, 12855, 12885, 
    12915, 12945, 12975, 13005, 13035, 13065, 13095, 13125, 13155, 13185, 
    13215, 13245, 13275, 13305, 13335, 13365, 13395, 13425, 13455, 13485, 
    13515, 13545, 13575, 13605, 13635, 13665, 13695, 13725, 13755, 13785, 
    13815, 13845, 13875, 13905, 13935, 13965, 13995, 14025, 14055, 14085, 
    14115, 14145, 14175, 14205, 14235, 14265, 14295, 14325, 14355, 14385, 
    14415, 14445, 14475, 14505, 14535, 14565, 14595, 14625, 14655, 14685, 
    14715, 14745, 14775, 14805, 14835, 14865, 14895, 14925, 14955, 14985, 
    15015, 15045, 15075, 15105, 15135, 15165, 15195, 15225, 15255, 15285, 
    15315, 15345, 15375, 15405, 15435, 15465, 15495, 15525, 15555, 15585, 
    15615, 15645, 15675, 15705, 15735, 15765, 15795, 15825, 15855, 15885, 
    15915, 15945, 15975, 16005, 16035, 16065, 16095, 16125, 16155, 16185, 
    16215, 16245, 16275, 16305, 16335, 16365, 16395, 16425, 16455, 16485, 
    16515, 16545, 16575, 16605, 16635, 16665, 16695, 16725, 16755, 16785, 
    16815, 16845, 16875, 16905, 16935, 16965, 16995, 17025, 17055, 17085, 
    17115, 17145, 17175, 17205, 17235, 17265, 17295, 17325, 17355, 17385, 
    17415, 17445, 17475, 17505, 17535, 17565, 17595, 17625, 17655, 17685, 
    17715, 17745, 17775, 17805, 17835, 17865, 17895, 17925, 17955, 17985, 
    18015, 18045, 18075, 18105, 18135, 18165, 18195, 18225, 18255, 18285, 
    18315, 18345, 18375, 18405, 18435, 18465, 18495, 18525, 18555, 18585, 
    18615, 18645, 18675, 18705, 18735, 18765, 18795, 18825, 18855, 18885, 
    18915, 18945, 18975, 19005, 19035, 19065, 19095, 19125, 19155, 19185, 
    19215, 19245, 19275, 19305, 19335, 19365, 19395, 19425, 19455, 19485, 
    19515, 19545, 19575, 19605, 19635, 19665, 19695, 19725, 19755, 19785, 
    19815, 19845, 19875, 19905, 19935, 19965, 19995, 20025, 20055, 20085, 
    20115, 20145, 20175, 20205, 20235, 20265, 20295, 20325, 20355, 20385, 
    20415, 20445, 20475, 20505, 20535, 20565, 20595, 20625, 20655, 20685, 
    20715, 20745, 20775, 20805, 20835, 20865, 20895, 20925, 20955, 20985, 
    21015, 21045, 21075, 21105, 21135, 21165, 21195, 21225, 21255, 21285, 
    21315, 21345, 21375, 21405, 21435, 21465, 21495, 21525, 21555, 21585, 
    21615, 21645, 21675, 21705, 21735, 21765, 21795, 21825, 21855, 21885, 
    21915, 21945, 21975, 22005, 22035, 22065, 22095, 22125, 22155, 22185, 
    22215, 22245, 22275, 22305, 22335, 22365, 22395, 22425, 22455, 22485, 
    22515, 22545, 22575, 22605, 22635, 22665, 22695, 22725, 22755, 22785, 
    22815, 22845, 22875, 22905, 22935, 22965, 22995, 23025, 23055, 23085, 
    23115, 23145, 23175, 23205, 23235, 23265, 23295, 23325, 23355, 23385, 
    23415, 23445, 23475, 23505, 23535, 23565, 23595, 23625, 23655, 23685, 
    23715, 23745, 23775, 23805, 23835, 23865, 23895, 23925, 23955, 23985, 
    24015, 24045, 24075, 24105, 24135, 24165, 24195, 24225, 24255, 24285, 
    24315, 24345, 24375, 24405, 24435, 24465, 24495, 24525, 24555, 24585, 
    24615, 24645, 24675, 24705, 24735, 24765, 24795, 24825, 24855, 24885, 
    24915, 24945, 24975, 25005, 25035, 25065, 25095, 25125, 25155, 25185, 
    25215, 25245, 25275, 25305, 25335, 25365, 25395, 25425, 25455, 25485, 
    25515, 25545 ], dtype='float64')
frt_dims=iris.coords.AuxCoord(frt,standard_name = 'forecast_reference_time',
                           units=cf_units.Unit('days since 1950-01-01 00:00:00', calendar='360_day'))
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
outpath='ukca_emiss_nC4H10.nc'
# don't want time to be cattable, as is a periodic emissions file
iris.FUTURE.netcdf_no_unlimited=True
# annoying hack to set a missing_value attribute as well as a _FillValue attribute
dict.__setitem__(ocube.attributes, 'missing_value', fillval)
# now write-out to netCDF
saver = iris.fileformats.netcdf.Saver(filename=outpath, netcdf_format='NETCDF3_CLASSIC')
saver.update_global_attributes(Conventions=iris.fileformats.netcdf.CF_CONVENTIONS_VERSION)
saver.write(ocube, local_keys=['vertical_scaling', 'missing_value','um_stash_source','tracer_name'])

# end of script
