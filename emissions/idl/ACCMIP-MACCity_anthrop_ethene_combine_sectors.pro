;IDL
;-----------------------------------------------------------------------------
;
;
;   ACCMIP-MACCity_anthrop_SPEC_combine_sectors.pro
;
;
;   This program reads a multi-annual ACCMIP-MACCity raw data emissions file 
;   of one species with emissions from all anthropogenic sectors combined into 
;   one mass flux value.
;   This data is split into annual data files and the timestamp is set to the 
;   exact middle of the month for a Gregorian calendar.
;
;   Monthly and annual totals for anthropogenic emissions are written to 
;   ASCII CSV formated data files.
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
accmipdir = 'emissions/ACCMIP-MACCity_anthrop_1960-2020/'

file = 'MACCity_anthro_ethene_1960-2020_98274.nc'

numyears = 61

varstring = 'MACCity'

monthly = 1  ; choose 1 if monthly total ascii output, otherwise annual total


numdays = [31,28,31,30,31,30,31,31,30,31,30,31]  ; ignore leap years
increment_nolpyr = [15.5,14.,15.5,15.,15.5,15.,15.5,15.5,15.,15.5,15.,15.5]
increment_lpyr   = [15.5,14.5,15.5,15.,15.5,15.,15.5,15.5,15.,15.5,15.,15.5]
secs_per_day = 86400.d


;------ set file name and coordinate space ------------------------------------

; coordinates at the centre of the grid box
lons = (findgen(720)*0.5)+0.25
ddlon = lons[1]-lons[0]
lats = ((findgen(360)*0.5)-89.75)

; coordinates at the edge of the grid box
dlon2 = findgen(720)*0.5
dlat2 = ((findgen(361)*0.5)-90.)



;---- calculate surface area of a sphere with 6371 km radius -------------------

rter   = 6371000.d   ; Earth radius in m
xpi    = acos(-1.d)
degrad = xpi/180.d

dlat = dblarr(n_elements(lats))
surf = dblarr(n_elements(lons),n_elements(lats))

radlats  = lats*degrad  ; convert latitudes to radians
radlats2 = dlat2*degrad

if( lats[0] gt lats[1] ) then begin
  ; latitudes N --> S
  for k=0,n_elements(lats)-1 do begin
     dlat(k) = sin(radlats2(k)) - sin(radlats2(k+1))
  endfor
endif else begin
  ; latitudes S --> N
  for k=0,n_elements(lats)-1 do begin
     dlat(k) = sin(radlats2(k+1)) - sin(radlats2(k))
  endfor
endelse

dlon = 2.0*xpi/float(n_elements(lons))

for k = 0,n_elements(lats)-1 do begin
for i = 0,n_elements(lons)-1 do begin
   surf[i,k] = dlon*rter*rter*dlat[k]
endfor
endfor

; control output:
print
print,'Total surface area: ',total(surf,/double)
print


print,'opening csv files to write out sector totals...'
openw, unit1, workspace+'MACCity_anthrop_ethene_monthly.csv', /get_lun
openw, unit2, workspace+'MACCity_anthrop_ethene_annual.csv', /get_lun


;---- read data from netcdf file ----------------------------------------------

ifn = workspace + accmipdir + file

ncid=ncdf_open(ifn,/nowrite)
print,'reading '+ifn

; read coordinate variables from netCDF file
lonid = ncdf_varid(ncid,'lon')
latid = ncdf_varid(ncid,'lat')
timeid = ncdf_varid(ncid,'date')

ncdf_varget,ncid,timeid,times  ; in days since 1960-01-01 00:00:00
if (n_elements(times) ne (numyears*12)) then begin
  print
  print,'-------------------------------------------'
  print,'WARNING!! Time dimension in emissions file is: ',n_elements(times)
  print,'This program expects ',numyears*12
  print,'-------------------------------------------'
  stop
endif
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
print,'file closed.'
print


;---- swap field -------------------------------------------------------------------

; swap longitudes from -180 --> 180 to 0 --> 360

newlons  = fltarr(n_elements(lons))
newlons[0:(n_elements(lons)/2)-1] = lons[(n_elements(lons)/2):n_elements(lons)-1]
newlons[(n_elements(lons)/2):(n_elements(lons)-1)] = lons[0:(n_elements(lons)/2)-1]+360.

newfield = fltarr(n_elements(lons),n_elements(lats),n_elements(times))
newfield[0:(n_elements(lons)/2)-1,*,*] = field[(n_elements(lons)/2):n_elements(lons)-1,*,*]
newfield[(n_elements(lons)/2):(n_elements(lons)-1),*,*] = field[0:(n_elements(lons)/2)-1,*,*]



;---- loop over years --------------------------------------------------------------

time = 0
outfield = fltarr(n_elements(newlons),n_elements(lats),12)  ; annual output file
outtimes = fltarr(12)

timeunits = 'days since 1960-01-01 00:00:00'
fldname   = 'emiss_flux'
varname   = 'Emissions Flux'
source    = 'ACCMIP MACCity anthropogenic emissions'
history   = 'combine_sector.pro'

for yr=0,numyears-1 do begin

  iyear = 1960+yr
  syear = strcompress(string(1960+yr),/remove_all)

  ems_ofn    = 'accmip_maccity_emissions_anthrop_ethene_all_sectors_'+syear+'_0.5x0.5.nc'

  print
  print
  print, 'Year = '+syear
  totalyear = 0.d

  ; check if leapyear:
  result = ( (fix(iyear mod 4) eq 0 AND fix(iyear mod 100) ne 0) $
                   OR (fix(iyear mod 400) eq 0) )
  if (result eq 1) then begin
    print,syear+' is leap year!'
    increment = increment_lpyr
  endif else begin
    increment = increment_nolpyr
  endelse

  for mth=0,11 do begin

     time = time + 1
     print, 'time index = ',time

     outfield[*,*,mth] =  newfield[*,*,time-1]
     outtimes[mth]     =  times[time-1]+increment[mth]

     printf, unit1, syear+'-'+strcompress(string(mth+1),/remove_all)+' , ', $
                      total(outfield[*,*,mth]*surf[*,*]*numdays[mth]*secs_per_day,/double)
     totalyear = totalyear + total(outfield[*,*,mth]*surf[*,*]*numdays[mth]*secs_per_day,/double)

  endfor

  printf, unit2, syear+' , ', totalyear


  print,'creating netcdf file: ',ems_ofn
  ncid=ncdf_create(workspace+ems_ofn,/clobber)

  timedim_id=ncdf_dimdef(ncid,'time',/unlimited)
  londim_id=ncdf_dimdef(ncid,'lon',n_elements(newlons))
  latdim_id=ncdf_dimdef(ncid,'lat',n_elements(lats))

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

  ncdf_varput,ncid,timevar_id,outtimes
  ncdf_varput,ncid,lonvar_id,newlons
  ncdf_varput,ncid,latvar_id,lats
  ncdf_varput,ncid,fieldvar_id,outfield

  ncdf_close,ncid

  print,'netCDF file closed.'

endfor

;---- close ascii file

free_lun, unit1
free_lun, unit2
print,'csv files closed.'
print

END

