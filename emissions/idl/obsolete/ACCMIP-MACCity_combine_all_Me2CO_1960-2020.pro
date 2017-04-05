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
anthrop_dir = workspace+'emissions/ACCMIP-MACCity_anthrop_1960-2020/Me2CO/'
bioburn_dir = workspace+'emissions/ACCMIP-MACCity_bioburn_1960-2008/Me2CO/historic/'

ofn = workspace+'emissions/ACCMIP-MACCity_Me2CO_combined.nc'

;------ no further changes should be needed below this line -------------------


;---- Open listing files with 61 file names for years 1960--2020.  

; Listing files have been created with   ls -1 *.nc > listing.anthrop  (or listing.bioburn)
; For bioburn emissions the ACCMIP_interpolated files for years 2009-2020 have to be linked
; (or copied) into the bioburn_dir directory and in listing.bioburn the file names need to be 
; moved chronologically to the end of the listing file to ensure a monotonous year progression

openr,alun,anthrop_dir+'listing.anthrop',/get_lun
openr,blun,bioburn_dir+'listing.bioburn',/get_lun

year=0L

while not eof(alun) do begin

  adummy =''
  bdummy =''
  readf,alun,adummy
  readf,blun,bdummy

;---- open anthropogenic emissions file of current year:

  ant_ifn = anthrop_dir+adummy
  print,1960+year,': ',ant_ifn

  ncid = ncdf_open(ant_ifn,/nowrite)
  timeid = ncdf_varid(ncid,'time')
  ncdf_varget,ncid,timeid,times

  if ( year eq 0L ) then begin

    lonid = ncdf_varid(ncid,'lon')
    ncdf_varget,ncid,lonid,lons
    latid = ncdf_varid(ncid,'lat')
    ncdf_varget,ncid,latid,lats

    bothflux = dblarr(n_elements(lons),n_elements(lats),n_elements(times))

  endif

  varid  = ncdf_varid(ncid,'emiss_flux')
  ncdf_attget,ncid,varid,'units',varunits
  ncdf_varget,ncid,varid,antflux
  ncdf_close,ncid

;---- open anthropogenic emissions file of current year:

  bio_ifn = bioburn_dir+bdummy
  print,1960+year,': ',bio_ifn

  ncid = ncdf_open(bio_ifn,/nowrite)
  varid  = ncdf_varid(ncid,'emiss_flux')
  ncdf_varget,ncid,varid,bioflux
  ncdf_close,ncid

;---- add fluxes to combined field

  if ( year eq 0L ) then begin

    bothflux = antflux + bioflux

  endif

;---- end loop over input files

  year = year+1

endwhile

close,/all  ; close listing files

;---- write out new combined emissions file for multiple years

timeunits='days since 1960-01-01 00:00:00'

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
ncdf_attput,ncid,fieldvar_id,'long_name','Surface acetone (C3H6O) emissions from all sectors (anthrop+bioburn)'
ncdf_attput,ncid,fieldvar_id,'molecular_weight',58.08,/float
ncdf_attput,ncid,fieldvar_id,'molecular_weight_units','g mol-1'

ncdf_attput,ncid,/global,'history','ACCMIP-MACCity_combine_all_Me2CO_1960-2020.pro'
ncdf_attput,ncid,/global,'source','Time-varying monthly emissions from 1960 to 2020 from the MACCity data set. MACCity provides anthropogenic emissions from 1960 to 2020 and biomass burning emissions from 1960 to 2008. Biomass burning emissions from 2009 to 2020 have been taken from the ACCMIP linearly interpolated RCP8.5 data set.'

ncdf_control,ncid,/endef

ncdf_varput,ncid,timevar_id,times
ncdf_varput,ncid,lonvar_id,lons
ncdf_varput,ncid,latvar_id,lats
ncdf_varput,ncid,fieldvar_id,bothflux

ncdf_close,ncid

print,'netCDF file closed.'


END
