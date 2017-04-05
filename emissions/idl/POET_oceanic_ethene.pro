;IDL
;-----------------------------------------------------------------------------
;
;
;   POET_oceanic_C2H6.pro
;
;
;   This program reads the 12 months POET raw data emissions file 
;   and converts it into a file which can be used for UKCA emissions.
;
;   The data is re-gridded to 0.5x0.5 degrees and latitudes and longitudes
;   are rearranged to match those of ACCMIP-MACCity emissions,
;   prior to writing the monthly 2D gridded fluxes to a netcdf file.
;
;   Monthly and annual totals for oceanic emissions are written out
;   to separate ascii files in csv format.
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

workspace = '/home/users/mkoehler/ukca_gws/emissions/POET_1990/raw_data/'

file    = 'POET_oceanic_ethene_1990_14938.nc'     ; raw data input file
ems_ofn = 'POET_oceanic_ethene_1990_processed.nc' ; output file with processed data

varstring = 'POET'  ; variable name in input file

surffile = '/home/users/mkoehler/ukca_gws/data/surf_half_by_half_2.nc'  ; surface area

numdays = [31,28,31,30,31,30,31,31,30,31,30,31]  ; ignore leap years
secs_per_day = 86400.d


;------ Read surface area file ------------------------------------------------

; -179.75 --> 197.75  (0.5 x 0.5 degrees)
; -89.75 --> 89.75

ncid=ncdf_open(surffile,/nowrite)

varid = ncdf_varid(ncid,'surf')
ncdf_varget,ncid,varid,surf

ncdf_close,ncid

print,'Total surface area: ',total(surf,/double)
print


;------ Open total output ascii files -----------------------------------------

print,'opening csv files to write out sector totals...'

openw, unit1, workspace+'/POET_oceanic_ethene_monthly.csv', /get_lun
openw, unit2, workspace+'/POET_oceanic_ethene_annual.csv', /get_lun

print


;---- Read data from input netcdf file ----------------------------------------

print,'opening input file: ',file

ifn = workspace + file

ncid=ncdf_open(ifn,/nowrite)
print,'reading '+ifn

; read coordinate variables from netCDF file
lonid = ncdf_varid(ncid,'lon')
latid = ncdf_varid(ncid,'lat')
timeid = ncdf_varid(ncid,'date')

ncdf_varget,ncid,timeid,times
ncdf_varget,ncid,lonid,lons
ncdf_varget,ncid,latid,lats

; read field variables and attributes

varid = ncdf_varid(ncid,varstring)
ncdf_attget,ncid,varid,'units',varunits
ncdf_attget,ncid,varid,'long_name',varlname

varlname=string(varlname)
varunits=string(varunits)
print,'reading ',varlname +' '+varunits

ncdf_varget,ncid,varid,field
print,'min val = ',min(field),' ', varunits
print,'max val = ',max(field),' ', varunits

ncdf_close,ncid
print,'input file closed.'
print


;---- Re-grid data to 0.5 x 0.5 degree grid ----------------------------------------

; As we are dealing with fluxes (kg m-2 s-1) the values of input field will be simply
; assigned to output grid without change of value.

field05 = fltarr(720,360,12)   ; Output field
                               ; 0.5 x 0.5 degrees (lon x lat), 12 monthly time steps

kk=0  ; counter for target latitudes at 0.5 degrees

for k=0,n_elements(lats)-1 do begin

  ii=0  ; counter for target longitudes at 0.5 degrees

  for i=0,n_elements(lons)-1 do begin

    field05[ii  ,kk  ,*] = field[i,k,*]
    field05[ii+1,kk  ,*] = field[i,k,*]
    field05[ii  ,kk+1,*] = field[i,k,*]
    field05[ii+1,kk+1,*] = field[i,k,*]

    ii = ii+2

  endfor

  kk = kk+2

endfor

; generate new longitude and latitudes

outlons = fltarr(720)
outlats = fltarr(360)

for i = 0,n_elements(outlons)-1 do begin
   outlons[i] = i*0.5 - 179.75
endfor

for k = 0,n_elements(outlats)-1 do begin
   outlats[k] = 89.75 - k*0.5
endfor


;---- Calculate total output -------------------------------------------------------

time = 0

outfield = fltarr(n_elements(outlons),n_elements(outlats),12)  ; annual output file
outtimes = fltarr(12)

totalyear = 0.d

for mth=0,n_elements(outtimes)-1 do begin

   time = time + 1
   print, 'time index = ',time

   outfield[*,*,mth] =  field05[*,*,time-1]

   totalmonth = total(outfield[*,*,mth]*surf[*,*]*numdays[mth]*secs_per_day,/double)

   printf, unit1, strcompress(string(mth+1),/remove_all)+' , ', totalmonth

   totalyear = totalyear + totalmonth

endfor

printf, unit2, '1990 , ', totalyear


;---- Close ascii file -------------------------------------------------------------

free_lun, unit1
free_lun, unit2
print,'csv files closed.'
print


;---- Re-arrange longitudes and latitudes ------------------------------------------

; swap latitudes to S --> N

print,'re-ordering oceanic emissions fluxes to ascending latitudes...'

tmpfield = dblarr(n_elements(outlons),n_elements(outlats),n_elements(times))
tmplats  = fltarr(n_elements(outlats))

for t=0,n_elements(times)-1 do begin
for k=0,n_elements(outlats)-1 do begin
   k_bar = (n_elements(outlats)-1)-k   ; k counting up from 0, k_bar counting down from 359
   tmpfield[*,k_bar,t] = field05[*,k,t]
endfor
endfor

field05 = tmpfield

for k=0,n_elements(outlats)-1 do begin   ; do the same for lats as reverse function not available
   k_bar = (n_elements(outlats)-1)-k
   tmplats[k_bar] = outlats[k]
endfor

outlats = tmplats

print,'re-ordering completed.'
tmpfield = 0b   ; to reduce memory requirements
tmplats  = 0b

print

; cycle longitudes from -180-->180 to 0-->360

print,'cycling longitudes to 0 --> 360...'

tmpfield = dblarr(n_elements(outlons),n_elements(outlats),n_elements(times))
tmplons  = fltarr(n_elements(outlons))

for i = 0,(n_elements(outlons)/2)-1 do $
   tmpfield[i,*,*] = field05[i+(n_elements(outlons)/2),*,*]

for i = (n_elements(outlons)/2),n_elements(outlons)-1 do $
   tmpfield[i,*,*] = field05[i-(n_elements(outlons)/2),*,*]

field05 = tmpfield

;   generate new longitudes array

for i=0,n_elements(outlons)-1 do $
   tmplons[i] = 0.25 + (i*(outlons[1]-outlons[0]))

outlons = tmplons

print,'cycling completed.'
tmpfield = 0b
tmplons  = 0b

print


;---- Write output file ------------------------------------------------------------

timeunits = 'days since 1990-01-01 00:00:00'
fldname   = 'emiss_flux'
varname   = 'Emissions Flux'
source    = 'POET oceanic emissions'
history   = 'POET_oceanic_ethene.pro'

print,'creating netCDF file: ',ems_ofn
ncid=ncdf_create(workspace+ems_ofn,/clobber)

timedim_id=ncdf_dimdef(ncid,'time',/unlimited)
londim_id=ncdf_dimdef(ncid,'lon',n_elements(outlons))
latdim_id=ncdf_dimdef(ncid,'lat',n_elements(outlats))

timevar_id=ncdf_vardef(ncid,'time',timedim_id,/float)
ncdf_attput,ncid,timevar_id,'units',timeunits
lonvar_id=ncdf_vardef(ncid,'lon',londim_id,/float)
ncdf_attput,ncid,lonvar_id,'name','longitude'
ncdf_attput,ncid,lonvar_id,'units','degrees_east'
latvar_id=ncdf_vardef(ncid,'lat',latdim_id,/float)
ncdf_attput,ncid,latvar_id,'name','latitude'
ncdf_attput,ncid,latvar_id,'units','degrees_north'

fieldvar_id=ncdf_vardef(ncid,fldname,[londim_id,latdim_id,timedim_id],/double)
ncdf_attput,ncid,fieldvar_id,'name',varname
ncdf_attput,ncid,fieldvar_id,'units',varunits

ncdf_attput,ncid,/global,'source',source
ncdf_attput,ncid,/global,'history',history
ncdf_attput,ncid,/global,'conventions','COARDS'

ncdf_control,ncid,/endef

ncdf_varput,ncid,timevar_id,times
ncdf_varput,ncid,lonvar_id,outlons
ncdf_varput,ncid,latvar_id,outlats
ncdf_varput,ncid,fieldvar_id,field05

ncdf_close,ncid

print,'netCDF file closed.'
print


END

