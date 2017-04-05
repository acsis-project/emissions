;IDL
;-----------------------------------------------------------------------------
;
;
;   ACCMIP_interpolated_SPEC_bioburn_2009-2020.pro
;
;
;   This program produces annual netcdf files with emission fluxes from
;   biomass burning emissions from the ACCMIP interpolated data set over 
;   the years 2009-2020.
;
;   These output files can be used to complement the ACCMIP-MACCity historic
;   biomass burning emissions beyond 2008 until 2020 in order to have
;   a complete anthropogenic and biomass burning data set for 1960-2020.
;
;   The time stamp has remained unchanged in these files.
;
;   This program is a derivative of ACCMIP_interpolated_SPEC_combine_sectors.pro 
;   which has here been reduced to consider biomass burning sectors only.
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
accmipdir = 'emissions/ACCMIP_interpolated_1850-2100/0.5x0.5/'


scenario  = 'RCP85' ; set to one of these: 'RCP26', 'RCP45', 'RCP60', 'RCP85'

year       = [ 2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019,2020 ]

numsteps          = 12   ; no of timesteps in file (e.g. 12 for monthly values)

numvar_file1      = 2
varstring_file1   = [  'emiss_gra', $
                       'emiss_for'  ]


;------ set file name and coordinate space ------------------------------------

; coordinates at the centre of the grid box
lons = (findgen(720)*0.5)+0.25
ddlon = lons[1]-lons[0]
lats = ((findgen(360)*0.5)-89.75)

; coordinates at the edge of the grid box
dlon2 = findgen(720)*0.5
dlat2 = ((findgen(361)*0.5)-90.)


; combined emissions array: dimensions(num_lons, num_lats, num_timesteps, num_sectors)

emsfield=dblarr(n_elements(lons),n_elements(lats),numsteps,numvar_file1)


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


;---- loop over years --------------------------------------------------------------


print,'opening csv files to write out sector totals...'
openw, unit1, workspace+'ACCMIP_annual_C3H8.csv', /get_lun
openw, unit2, workspace+'ACCMIP_bioburn_monthly_C3H8.csv', /get_lun


for yr=0,n_elements(year)-1 do begin

  syear = strcompress(string(year[yr]),/remove_all)

  ifp = workspace + accmipdir + syear +'/'

  print
  print
  print, 'Year = '+syear
  print, ifp

  ems_file1  = 'accmip_interpolated_emissions_'+scenario+'_propane_biomassburning_'+syear+'_0.5x0.5.nc'
  ems_ofn    = 'accmip_interpolated_emissions_'+scenario+'_C3H8_combined_bioburn_'+syear+'_0.5x0.5.nc'

  ; unzip netcdf data files
  print,'unzipping file...'
  spawn,'gunzip '+ifp+ems_file1+'.gz'

  ;---- read data from ems_file1 netcdf file ------------------------------------

  ncid=ncdf_open(ifp+ems_file1,/nowrite)
  print,'reading '+ems_file1

  ; read coordinate variables from netCDF file
  lonid = ncdf_varid(ncid,'lon')
  latid = ncdf_varid(ncid,'lat')
  timeid = ncdf_varid(ncid,'time')

  ncdf_varget,ncid,timeid,times  ; in days since 1850-01-01 00:00:00
  if (n_elements(times) ne numsteps) then begin
    print
    print,'-------------------------------------------'
    print,'WARNING!! Time dimension in emissions file is: ',n_elements(times)
    print,'This program expects ',numsteps
    print,'-------------------------------------------'
    stop
  endif
  ncdf_varget,ncid,lonid,lons
  ncdf_varget,ncid,latid,lats

  ; read field variables and attributes

  for v=0,numvar_file1-1 do begin

     print, 'Variable: ',v+1
     varid = ncdf_varid(ncid,varstring_file1[v])
     ncdf_attget,ncid,varid,'units',varunits
     ncdf_attget,ncid,varid,'long_name',varlname

     varlname=string(varlname)
     varunits=string(varunits)
     print,'reading ',varlname +' '+varunits

     ncdf_varget,ncid,varid,field
     print,'min val = ',min(field),' ', varunits
     print,'max val = ',max(field),' ', varunits

     emsfield(*,*,*,v) = field

  endfor

  ncdf_close,ncid
  print,'file closed.'
  print


  ;---- write out total monthly species emissions file for current year ---------

  outfield = dblarr(n_elements(lons),n_elements(lats),n_elements(times))

  for v=0,(numvar_file1)-1 do begin

     outfield[*,*,*] = outfield[*,*,*] + emsfield[*,*,*,v]

  endfor

  timeunits = 'days since 1850-01-01 00:00:00'
  fldname   = 'emiss_flux'
  varname   = 'Emissions Flux'
  source    = 'ACCMIP interpolated emissions'
  history   = 'combine_sector.pro'
 
  print,'creating netcdf file: ',ems_ofn
  ncid=ncdf_create(workspace+ems_ofn,/clobber)

  timedim_id=ncdf_dimdef(ncid,'time',/unlimited)
  londim_id=ncdf_dimdef(ncid,'lon',n_elements(lons))
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

  ncdf_varput,ncid,timevar_id,times
  ncdf_varput,ncid,lonvar_id,lons
  ncdf_varput,ncid,latvar_id,lats
  ncdf_varput,ncid,fieldvar_id,outfield

  ncdf_close,ncid

  print,'netCDF file closed.'


  ;---- calculate annual total emitted species mass for each sector -----------

  numdays = [31,28,31,30,31,30,31,31,30,31,30,31]  ; ignore leap years
  secs_per_day = 86400.d
  emstotal = dblarr(numvar_file1)

  for sector = 0,(numvar_file1)-1 do begin

    for t = 0,n_elements(times)-1 do begin

      emstotal[sector] = emstotal[sector] + $
                         total(emsfield[*,*,t,sector]*surf[*,*]*double(numdays[t])*secs_per_day,/double)

    endfor

  endfor

  monthtotal=0.d

  for t = 0,n_elements(times)-1 do begin
     monthtotal = total(emsfield[*,*,t,0]*surf[*,*]*double(numdays[t])*secs_per_day,/double) $
                + total(emsfield[*,*,t,1]*surf[*,*]*double(numdays[t])*secs_per_day,/double)
     printf, unit2, syear+'-'+strcompress(string(t+1),/remove_all)+' , ',monthtotal
  endfor

  ; add all biomass burning sectors (for C3H8 that's 0-1)
  printf, unit1, syear,',',emstotal[0],',',$
                           emstotal[1],',',total(emstotal,/double)
 

  ; zip up netcdf data files
  print,'zipping up file...'
  spawn,'gzip '+ifp+ems_file1


;---- end loop over years

endfor

;---- close ascii file

free_lun, unit1
free_lun, unit2
print,'csv files closed.'
print

END

