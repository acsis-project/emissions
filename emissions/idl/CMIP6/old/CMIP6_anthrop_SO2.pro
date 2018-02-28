;IDL
;-----------------------------------------------------------------------------
;
;
;   CMIP6_anthrop_SO2.pro
;
;
;   This program reads a multi-annual CEDS CMIP6 raw data emissions file 
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

workspace = '/home/users/mkoehler/ukca_gws/emissions/CMIP6'

file1 = 'SO2-em-anthro_input4MIPs_emissions_CMIP_CEDS-v2016-07-26-sectorDim_gr_195001-199912.nc'
file2 = 'SO2-em-anthro_input4MIPs_emissions_CMIP_CEDS-v2016-07-26-sectorDim_gr_200001-201412.nc'

numyears = 50
startyear = 1950

sectors = 8
varstring = 'SO2_em_anthro'

monthly = 1  ; choose 1 if monthly total ascii output, otherwise annual total

surffile = '/home/users/mkoehler/ukca_gws/data/surf_half_by_half_2.nc'

numdays = [31,28,31,30,31,30,31,31,30,31,30,31]  ; ignore leap years
increment_nolpyr = [15.5,14.,15.5,15.,15.5,15.,15.5,15.5,15.,15.5,15.,15.5]
increment_lpyr   = [15.5,14.5,15.5,15.,15.5,15.,15.5,15.5,15.,15.5,15.,15.5]
secs_per_day = 86400.d


;------ read surface area file ------------------------------------------------

; -179.75 --> 197.75  (0.5 x 0.5 degrees)
; -89.75 --> 89.75

ncid=ncdf_open(surffile,/nowrite)

lonid = ncdf_varid(ncid,'lon')
latid = ncdf_varid(ncid,'lat')
ncdf_varget,ncid,lonid,lons
ncdf_varget,ncid,latid,lats

varid = ncdf_varid(ncid,'surf')
ncdf_varget,ncid,varid,surf

ncdf_close,ncid

print,'Total surface area: ',total(surf,/double)
print


;------ open total output ascii files -----------------------------------------

print,'opening csv files to write out sector totals...'
openw, unit1, workspace+'/CMIP6_anthrop_SO2_monthly.csv', /get_lun
openw, unit2, workspace+'/CMIP6_anthrop_SO2_annual.csv', /get_lun


;---- read data from netcdf file ----------------------------------------------

ifn = workspace + '/' + file1

ncid=ncdf_open(ifn,/nowrite)
print,'reading '+ifn

; read coordinate variables from netCDF file
lonid = ncdf_varid(ncid,'lon')
latid = ncdf_varid(ncid,'lat')
timeid = ncdf_varid(ncid,'time')

ncdf_varget,ncid,timeid,times  ; in days since 1750-01-01 00:00:00
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

;newlons  = fltarr(n_elements(lons))
;newlons[0:(n_elements(lons)/2)-1] = lons[(n_elements(lons)/2):n_elements(lons)-1]
;newlons[(n_elements(lons)/2):(n_elements(lons)-1)] = lons[0:(n_elements(lons)/2)-1]+360.

;newfield = fltarr(n_elements(lons),n_elements(lats),sectors,n_elements(times))
;newfield[0:(n_elements(lons)/2)-1,*,*,*] = field[(n_elements(lons)/2):n_elements(lons)-1,*,*,*]
;newfield[(n_elements(lons)/2):(n_elements(lons)-1),*,*,*] = field[0:(n_elements(lons)/2)-1,*,*,*]



;---- loop over years --------------------------------------------------------------

time = 0
;outfield = fltarr(n_elements(newlons),n_elements(lats),sectors,12)  ; annual output file
outfield = fltarr(n_elements(lons),n_elements(lats),sectors,12)  ; annual output file
outtimes = fltarr(12)

;timeunits = 'days since 1960-01-01 00:00:00'
;fldname   = 'emiss_flux'
;varname   = 'Emissions Flux'
;source    = 'ACCMIP MACCity anthropogenic emissions'
;history   = 'combine_sector.pro'

for yr=0,numyears-1 do begin

  iyear = startyear+yr
  syear = strcompress(string(startyear+yr),/remove_all)
; iyear = 1960+yr
; syear = strcompress(string(1960+yr),/remove_all)

; ems_ofn    = 'accmip_maccity_emissions_anthrop_SO2_all_sectors_'+syear+'_0.5x0.5.nc'

  print
  print
  print, 'Year = '+syear
  totalyear = 0.d

; ; check if leapyear:
; result = ( (fix(iyear mod 4) eq 0 AND fix(iyear mod 100) ne 0) $
;                  OR (fix(iyear mod 400) eq 0) )
; if (result eq 1) then begin
;   print,syear+' is leap year!'
;   increment = increment_lpyr
; endif else begin
;   increment = increment_nolpyr
; endelse

  for mth=0,n_elements(outtimes)-1 do begin

     time = time + 1
     print, 'time index = ',time

     ;outfield[*,*,*,mth] =  newfield[*,*,*,time-1]
     outfield[*,*,*,mth] =  field[*,*,*,time-1]
     ;outtimes[mth]     =  times[time-1]+increment[mth]

     totalmonth = 0.d
     for s=0,sectors-1 do begin

        totalmonth = totalmonth + $
                     total(outfield[*,*,s,mth]*surf[*,*]*numdays[mth]*secs_per_day,/double)

     endfor
     printf, unit1, syear+'-'+strcompress(string(mth+1),/remove_all)+' , ', totalmonth

     totalyear = totalyear + totalmonth

  endfor

  printf, unit2, syear+' , ', totalyear


; print,'creating netcdf file: ',ems_ofn
; ncid=ncdf_create(workspace+ems_ofn,/clobber)

; timedim_id=ncdf_dimdef(ncid,'time',/unlimited)
; londim_id=ncdf_dimdef(ncid,'lon',n_elements(newlons))
; latdim_id=ncdf_dimdef(ncid,'lat',n_elements(lats))

; timevar_id=ncdf_vardef(ncid,'time',timedim_id,/float)
; ncdf_attput,ncid,timevar_id,'units',timeunits
; lonvar_id=ncdf_vardef(ncid,'lon',londim_id,/float)
; ncdf_attput,ncid,lonvar_id,'name','longitude'
; ncdf_attput,ncid,lonvar_id,'units','degrees_east'
; latvar_id=ncdf_vardef(ncid,'lat',latdim_id,/float)
; ncdf_attput,ncid,latvar_id,'name','latitude'
; ncdf_attput,ncid,latvar_id,'units','degrees_north'

; fieldvar_id=ncdf_vardef(ncid,fldname,[londim_id,latdim_id,timedim_id],/double)
; ncdf_attput,ncid,fieldvar_id,'name',varname
; ncdf_attput,ncid,fieldvar_id,'units',varunits

; ncdf_attput,ncid,/global,'source',source
; ncdf_attput,ncid,/global,'history',history
; ncdf_attput,ncid,/global,'conventions','COARDS'

; ncdf_control,ncid,/endef

; ncdf_varput,ncid,timevar_id,outtimes
; ncdf_varput,ncid,lonvar_id,newlons
; ncdf_varput,ncid,latvar_id,lats
; ncdf_varput,ncid,fieldvar_id,outfield

; ncdf_close,ncid

; print,'netCDF file closed.'

endfor

;---- close ascii file

free_lun, unit1
free_lun, unit2
print,'csv files closed.'
print

END

