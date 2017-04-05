;IDL
;-----------------------------------------------------------------------------
;
;
;   ACCMIP-MACCity_combine_all_SPEC_1960-2020.pro
;
;
;   This program reads annual ACCMIP-MACCity processed emissions files
;   (one anthropogenic and one biomass burning emissions file per year)
;   and combines all the data into one netCDF file using one joint emissions
;   mass flux for the emitted specie.
;
;   The time stamp of the emissions will be taken fro the anthropogenic emissions.
;
;   This version works with 2D surface emissions fields.
;
;
;   Author: Marcus Koehler
;   $Date: $
;   $Revision: $
;
;   $Id: $
;
;
;-----------------------------------------------------------------------------

;------ set file paths and variable names -------------------------------------

; path variables for raw data input files:

workspace = '/group_workspaces/jasmin2/ukca/vol1/mkoehler/'
bioburn_dir = workspace+'emissions/ACCMIP-MACCity_bioburn_1960-2008/C5H8/historic/'

ofn = workspace+'emissions/ACCMIP-MACCity_C5H8_combined.nc'

;------ no further changes should be needed below this line -------------------


;---- Open listing files with 61 file names for years 1960--2020.  

; Listing files have been created with   ls -1 *.nc > listing.anthrop  (or listing.bioburn)
; For bioburn emissions the ACCMIP_interpolated files for years 2009-2020 have to be linked
; (or copied) into the bioburn_dir directory and in listing.bioburn the file names need to be 
; moved chronologically to the end of the listing file to ensure a monotonous year progression

openr,blun,bioburn_dir+'listing.bioburn',/get_lun

year=0L

while not eof(blun) do begin

  bdummy =''
  readf,blun,bdummy


;---- open anthropogenic emissions file of current year:

  bio_ifn = bioburn_dir+bdummy
  print,1960+year,': ',bio_ifn

  ncid = ncdf_open(bio_ifn,/nowrite)
  timeid = ncdf_varid(ncid,'time')
  ncdf_varget,ncid,timeid,times

  if ( year eq 0L ) then begin

    lonid = ncdf_varid(ncid,'lon')
    ncdf_varget,ncid,lonid,lons
    latid = ncdf_varid(ncid,'lat')
    ncdf_varget,ncid,latid,lats

  endif

  varid  = ncdf_varid(ncid,'emiss_flux')
  ncdf_varget,ncid,varid,bioflux
  ncdf_close,ncid


;---- end loop over input files

  year = year+1

endwhile

close,/all  ; close listing files

;---- write out new combined emissions file for multiple years

timeunits='days since 1960-01-01 00:00:00'

outtimes = [ 15.5, 45.5, 75.5, 106, 136.5, 167, 197.5, 228.5, 259, 289.5, 320, $
    350.5, 381.5, 411, 440.5, 471, 501.5, 532, 562.5, 593.5, 624, 654.5, 685, $
    715.5, 746.5, 776, 805.5, 836, 866.5, 897, 927.5, 958.5, 989, 1019.5, $
    1050, 1080.5, 1111.5, 1141, 1170.5, 1201, 1231.5, 1262, 1292.5, 1323.5, $
    1354, 1384.5, 1415, 1445.5, 1476.5, 1506.5, 1536.5, 1567, 1597.5, 1628, $
    1658.5, 1689.5, 1720, 1750.5, 1781, 1811.5, 1842.5, 1872, 1901.5, 1932, $
    1962.5, 1993, 2023.5, 2054.5, 2085, 2115.5, 2146, 2176.5, 2207.5, 2237, $
    2266.5, 2297, 2327.5, 2358, 2388.5, 2419.5, 2450, 2480.5, 2511, 2541.5, $
    2572.5, 2602, 2631.5, 2662, 2692.5, 2723, 2753.5, 2784.5, 2815, 2845.5, $
    2876, 2906.5, 2937.5, 2967.5, 2997.5, 3028, 3058.5, 3089, 3119.5, 3150.5, $
    3181, 3211.5, 3242, 3272.5, 3303.5, 3333, 3362.5, 3393, 3423.5, 3454, $
    3484.5, 3515.5, 3546, 3576.5, 3607, 3637.5, 3668.5, 3698, 3727.5, 3758, $
    3788.5, 3819, 3849.5, 3880.5, 3911, 3941.5, 3972, 4002.5, 4033.5, 4063, $
    4092.5, 4123, 4153.5, 4184, 4214.5, 4245.5, 4276, 4306.5, 4337, 4367.5, $
    4398.5, 4428.5, 4458.5, 4489, 4519.5, 4550, 4580.5, 4611.5, 4642, 4672.5, $
    4703, 4733.5, 4764.5, 4794, 4823.5, 4854, 4884.5, 4915, 4945.5, 4976.5, $
    5007, 5037.5, 5068, 5098.5, 5129.5, 5159, 5188.5, 5219, 5249.5, 5280, $
    5310.5, 5341.5, 5372, 5402.5, 5433, 5463.5, 5494.5, 5524, 5553.5, 5584, $
    5614.5, 5645, 5675.5, 5706.5, 5737, 5767.5, 5798, 5828.5, 5859.5, 5889.5, $
    5919.5, 5950, 5980.5, 6011, 6041.5, 6072.5, 6103, 6133.5, 6164, 6194.5, $
    6225.5, 6255, 6284.5, 6315, 6345.5, 6376, 6406.5, 6437.5, 6468, 6498.5, $
    6529, 6559.5, 6590.5, 6620, 6649.5, 6680, 6710.5, 6741, 6771.5, 6802.5, $
    6833, 6863.5, 6894, 6924.5, 6955.5, 6985, 7014.5, 7045, 7075.5, 7106, $
    7136.5, 7167.5, 7198, 7228.5, 7259, 7289.5, 7320.5, 7350.5, 7380.5, 7411, $
    7441.5, 7472, 7502.5, 7533.5, 7564, 7594.5, 7625, 7655.5, 7686.5, 7716, $
    7745.5, 7776, 7806.5, 7837, 7867.5, 7898.5, 7929, 7959.5, 7990, 8020.5, $
    8051.5, 8081, 8110.5, 8141, 8171.5, 8202, 8232.5, 8263.5, 8294, 8324.5, $
    8355, 8385.5, 8416.5, 8446, 8475.5, 8506, 8536.5, 8567, 8597.5, 8628.5, $
    8659, 8689.5, 8720, 8750.5, 8781.5, 8811.5, 8841.5, 8872, 8902.5, 8933, $
    8963.5, 8994.5, 9025, 9055.5, 9086, 9116.5, 9147.5, 9177, 9206.5, 9237, $
    9267.5, 9298, 9328.5, 9359.5, 9390, 9420.5, 9451, 9481.5, 9512.5, 9542, $
    9571.5, 9602, 9632.5, 9663, 9693.5, 9724.5, 9755, 9785.5, 9816, 9846.5, $
    9877.5, 9907, 9936.5, 9967, 9997.5, 10028, 10058.5, 10089.5, 10120, $
    10150.5, 10181, 10211.5, 10242.5, 10272.5, 10302.5, 10333, 10363.5, $
    10394, 10424.5, 10455.5, 10486, 10516.5, 10547, 10577.5, 10608.5, 10638, $
    10667.5, 10698, 10728.5, 10759, 10789.5, 10820.5, 10851, 10881.5, 10912, $
    10942.5, 10973.5, 11003, 11032.5, 11063, 11093.5, 11124, 11154.5, $
    11185.5, 11216, 11246.5, 11277, 11307.5, 11338.5, 11368, 11397.5, 11428, $
    11458.5, 11489, 11519.5, 11550.5, 11581, 11611.5, 11642, 11672.5, $
    11703.5, 11733.5, 11763.5, 11794, 11824.5, 11855, 11885.5, 11916.5, $
    11947, 11977.5, 12008, 12038.5, 12069.5, 12099, 12128.5, 12159, 12189.5, $
    12220, 12250.5, 12281.5, 12312, 12342.5, 12373, 12403.5, 12434.5, 12464, $
    12493.5, 12524, 12554.5, 12585, 12615.5, 12646.5, 12677, 12707.5, 12738, $
    12768.5, 12799.5, 12829, 12858.5, 12889, 12919.5, 12950, 12980.5, $
    13011.5, 13042, 13072.5, 13103, 13133.5, 13164.5, 13194.5, 13224.5, $
    13255, 13285.5, 13316, 13346.5, 13377.5, 13408, 13438.5, 13469, 13499.5, $
    13530.5, 13560, 13589.5, 13620, 13650.5, 13681, 13711.5, 13742.5, 13773, $
    13803.5, 13834, 13864.5, 13895.5, 13925, 13954.5, 13985, 14015.5, 14046, $
    14076.5, 14107.5, 14138, 14168.5, 14199, 14229.5, 14260.5, 14290, $
    14319.5, 14350, 14380.5, 14411, 14441.5, 14472.5, 14503, 14533.5, 14564, $
    14594.5, 14625.5, 14655.5, 14685.5, 14716, 14746.5, 14777, 14807.5, $
    14838.5, 14869, 14899.5, 14930, 14960.5, 14991.5, 15021, 15050.5, 15081, $
    15111.5, 15142, 15172.5, 15203.5, 15234, 15264.5, 15295, 15325.5, $
    15356.5, 15386, 15415.5, 15446, 15476.5, 15507, 15537.5, 15568.5, 15599, $
    15629.5, 15660, 15690.5, 15721.5, 15751, 15780.5, 15811, 15841.5, 15872, $
    15902.5, 15933.5, 15964, 15994.5, 16025, 16055.5, 16086.5, 16116.5, $
    16146.5, 16177, 16207.5, 16238, 16268.5, 16299.5, 16330, 16360.5, 16391, $
    16421.5, 16452.5, 16482, 16511.5, 16542, 16572.5, 16603, 16633.5, $
    16664.5, 16695, 16725.5, 16756, 16786.5, 16817.5, 16847, 16876.5, 16907, $
    16937.5, 16968, 16998.5, 17029.5, 17060, 17090.5, 17121, 17151.5, $
    17182.5, 17212, 17241.5, 17272, 17302.5, 17333, 17363.5, 17394.5, 17425, $
    17455.5, 17486, 17516.5, 17547.5, 17577.5, 17607.5, 17638, 17668.5, $
    17699, 17729.5, 17760.5, 17791, 17821.5, 17852, 17882.5, 17913.5, 17943, $
    17972.5, 18003, 18033.5, 18064, 18094.5, 18125.5, 18156, 18186.5, 18217, $
    18247.5, 18278.5, 18308, 18337.5, 18368, 18398.5, 18429, 18459.5, $
    18490.5, 18521, 18551.5, 18582, 18612.5, 18643.5, 18673, 18702.5, 18733, $
    18763.5, 18794, 18824.5, 18855.5, 18886, 18916.5, 18947, 18977.5, $
    19008.5, 19038.5, 19068.5, 19099, 19129.5, 19160, 19190.5, 19221.5, $
    19252, 19282.5, 19313, 19343.5, 19374.5, 19404, 19433.5, 19464, 19494.5, $
    19525, 19555.5, 19586.5, 19617, 19647.5, 19678, 19708.5, 19739.5, 19769, $
    19798.5, 19829, 19859.5, 19890, 19920.5, 19951.5, 19982, 20012.5, 20043, $
    20073.5, 20104.5, 20134, 20163.5, 20194, 20224.5, 20255, 20285.5, $
    20316.5, 20347, 20377.5, 20408, 20438.5, 20469.5, 20499.5, 20529.5, $
    20560, 20590.5, 20621, 20651.5, 20682.5, 20713, 20743.5, 20774, 20804.5, $
    20835.5, 20865, 20894.5, 20925, 20955.5, 20986, 21016.5, 21047.5, 21078, $
    21108.5, 21139, 21169.5, 21200.5, 21230, 21259.5, 21290, 21320.5, 21351, $
    21381.5, 21412.5, 21443, 21473.5, 21504, 21534.5, 21565.5, 21595, $
    21624.5, 21655, 21685.5, 21716, 21746.5, 21777.5, 21808, 21838.5, 21869, $
    21899.5, 21930.5, 21960.5, 21990.5, 22021, 22051.5, 22082, 22112.5, $
    22143.5, 22174, 22204.5, 22235, 22265.5 ]

print,'creating netcdf file: ',ofn
ncid=ncdf_create(ofn,/clobber)

timedim_id=ncdf_dimdef(ncid,'time',/unlimited)
londim_id=ncdf_dimdef(ncid,'lon',n_elements(lons))
latdim_id=ncdf_dimdef(ncid,'lat',n_elements(lats))

timevar_id=ncdf_vardef(ncid,'time',timedim_id,/float)
ncdf_attput,ncid,timevar_id,'units',timeunits
ncdf_attput,ncid,timevar_id,'calendar','gregorian'
lonvar_id=ncdf_vardef(ncid,'lon',londim_id,/float)
ncdf_attput,ncid,lonvar_id,'name','longitude'
ncdf_attput,ncid,lonvar_id,'units','degrees_east'
latvar_id=ncdf_vardef(ncid,'lat',latdim_id,/float)
ncdf_attput,ncid,latvar_id,'name','latitude'
ncdf_attput,ncid,latvar_id,'units','degrees_north'

fieldvar_id=ncdf_vardef(ncid,'emiss_flux',[londim_id,latdim_id,timedim_id],/double)
ncdf_attput,ncid,fieldvar_id,'units','kg m-2 s-1'
ncdf_attput,ncid,fieldvar_id,'long_name','Surface C5H8 emissions from biomass burning sectors expressed as carbon'
ncdf_attput,ncid,fieldvar_id,'molecular_weight',68.12,/float
ncdf_attput,ncid,fieldvar_id,'molecular_weight_units','g mol-1'

ncdf_attput,ncid,/global,'history','ACCMIP-MACCity_combine_all_C5H8_1960-2020.pro'
ncdf_attput,ncid,/global,'source','Time-varying monthly emissions from 1960 to 2020 from the MACCity data set. MACCity provides biomass burning emissions from 1960 to 2008. Biomass burning emissions from 2009 to 2020 have been taken from the ACCMIP linearly interpolated RCP8.5 data set. There are no anthropogenic C5H8 emissions in this data set.'

ncdf_control,ncid,/endef

ncdf_varput,ncid,timevar_id,outtimes
ncdf_varput,ncid,lonvar_id,lons
ncdf_varput,ncid,latvar_id,lats
ncdf_varput,ncid,fieldvar_id,bioflux

ncdf_close,ncid

print,'netCDF file closed.'


END
