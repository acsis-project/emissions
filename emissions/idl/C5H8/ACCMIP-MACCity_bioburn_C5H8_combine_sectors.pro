;IDL
;-----------------------------------------------------------------------------
;
;
;   ACCMIP-MACCity_bioburn_SPEC_combine_sectors.pro
;
;
;   This program reads annual ACCMIP-MACCity raw data emissions files 
;   of one species with emissions from two biomass burning sectors.
;   The data is combined to one mass flux value for biomass burning and 
;   written out as monthly data for individual years.
;
;   The time stamp of the emissions remains unchanged but corresponds to those
;   from the anthropogenic MACCity emissions.
;
;   An ASCII CSV formated data file is generated which contains sector totals
;   per year.
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
accmipdir = 'emissions/ACCMIP-MACCity_bioburn_1960-2008/0.5x0.5/'


scenario  = 'historic' ; set to one of these: 'historic', 'RCP26', 'RCP45', 'RCP60', 'RCP85'

year      = [1960,1961,1962,1963,1964,1965,1966,1967,1968,1969, $
             1970,1971,1972,1973,1974,1975,1976,1977,1978,1979, $
             1980,1981,1982,1983,1984,1985,1986,1987,1988,1989, $
             1990,1991,1992,1993,1994,1995,1996,1997,1998,1999, $
             2000,2001,2002,2003,2004,2005,2006,2007,2008]


numsteps          = 12   ; no of timesteps in file (e.g. 12 for monthly values)

numvar_file1      = 2
varstring_file1   = [  'emiss_gra', $
                       'emiss_for'  ]

numvar_file2      = 0
varstring_file2   = [  'emiss_awb', $
                       'emiss_dom', $
                       'emiss_ene', $
                       'emiss_ind', $
                       'emiss_tra', $
                       'emiss_wst', $
                       'emiss_agr', $
                       'emiss_slv'  ]

numvar_file3      = 0
varstring_file3   = [  'emiss_shp'  ]



;------ set file name and coordinate space ------------------------------------

; coordinates at the centre of the grid box
lons = (findgen(720)*0.5)+0.25
ddlon = lons[1]-lons[0]
lats = ((findgen(360)*0.5)-89.75)

; coordinates at the edge of the grid box
dlon2 = findgen(720)*0.5
dlat2 = ((findgen(361)*0.5)-90.)


; combined emissions array: dimensions(num_lons, num_lats, num_timesteps, num_sectors)
emsfield=dblarr(n_elements(lons),n_elements(lats),numsteps, $
                numvar_file1+numvar_file2+numvar_file3)


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


print,'opening csv file to write out sector totals...'
openw, unit, workspace+'MACCity_C5H8_bioburn.csv', /get_lun


for yr=0,n_elements(year)-1 do begin

  syear = strcompress(string(year[yr]),/remove_all)

  ifp = workspace + accmipdir + syear +'/'

  print
  print
  print, 'Year = '+syear
  print, ifp

  ems_file1  = 'accmip_maccity_emissions_'+scenario+'_isoprene_biomassburning_'+syear+'_0.5x0.5.nc'
;  ems_file2  = 'accmip_interpolated_emissions_'+scenario+'_isoprene_biomassburning_'+syear+'_0.5x0.5.nc'
;  ems_file3  = 'accmip_interpolated_emissions_'+scenario+'_isoprene_ships_'+syear+'_0.5x0.5.nc'

  ems_ofn    = 'accmip_maccity_emissions_'+scenario+'_C5H8_all_sectors_'+syear+'_0.5x0.5.nc'

  ; unzip netcdf data files
  print,'unzipping files...'
  spawn,'gunzip '+ifp+ems_file1+'.gz'
;  spawn,'gunzip '+ifp+ems_file2+'.gz'
;  spawn,'gunzip '+ifp+ems_file3+'.gz'

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

; ;---- read data from ems_file2 netcdf file --------------------------------------
;
; ncid=ncdf_open(ifp+ems_file2,/nowrite)
; print,'reading '+ems_file2
;
; ; read field variables and attributes
;
; for v=0,numvar_file2-1 do begin
;
;    print, 'Variable: ',v+numvar_file1+1
;    varid = ncdf_varid(ncid,varstring_file2[v])
;    ncdf_attget,ncid,varid,'units',varunits
;    ncdf_attget,ncid,varid,'long_name',varlname
;
;    varlname=string(varlname)
;    varunits=string(varunits)
;    print,'reading ',varlname +' '+varunits
;
;    ncdf_varget,ncid,varid,field
;    print,'min val = ',min(field),' ', varunits
;    print,'max val = ',max(field),' ', varunits
;
;    emsfield(*,*,*,v+numvar_file1) = field
;
; endfor
;
; ncdf_close,ncid
; print,'file closed.'
; print
;
; ;---- read data from ems_file3 netcdf file ---------------------------------------
;
; ncid=ncdf_open(ifp+ems_file3,/nowrite)
; print,'reading '+ems_file3
;
; ; read field variables and attributes
;
; for v=0,numvar_file3-1 do begin
;
;    print, 'Variable: ',v+numvar_file1+numvar_file2+1
;    varid = ncdf_varid(ncid,varstring_file3[v])
;    ncdf_attget,ncid,varid,'units',varunits
;    ncdf_attget,ncid,varid,'long_name',varlname
;
;    varlname=string(varlname)
;    varunits=string(varunits)
;    print,'reading ',varlname +' '+varunits
;
;    ncdf_varget,ncid,varid,field
;    print,'min val = ',min(field),' ', varunits
;    print,'max val = ',max(field),' ', varunits
;
;    emsfield[*,*,*,v+numvar_file1+numvar_file2] = field
;
; endfor
;
; ncdf_close,ncid
; print,'file closed.'
; print

  ;---- write out total monthly species emissions file for current year ---------

  outfield = dblarr(n_elements(lons),n_elements(lats),n_elements(times))

  for v=0,(numvar_file1+numvar_file2+numvar_file3)-1 do begin

     outfield[*,*,*] = outfield[*,*,*] + emsfield[*,*,*,v]

  endfor

  timeunits = 'days since 1850-01-01 00:00:00'
  fldname   = 'emiss_flux'
  varname   = 'Emissions Flux'
  source    = 'ACCMIP MACCity Biomass Burning emissions'
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
  emstotal = dblarr(numvar_file1+numvar_file2+numvar_file3)

  for sector = 0,(numvar_file1+numvar_file2+numvar_file3)-1 do begin

    for t = 0,n_elements(times)-1 do begin

      emstotal[sector] = emstotal[sector] + $
                         total(emsfield[*,*,t,sector]*surf[*,*]*double(numdays[t])*secs_per_day,/double)

    endfor

  endfor

  printf, unit, syear,',',emstotal[ 0],',',$
                          emstotal[ 1],',',$
;                         emstotal[ 2],',',$
;                         emstotal[ 3],',',$
;                         emstotal[ 4],',',$
;                         emstotal[ 5],',',$
;                         emstotal[ 6],',',$
;                         emstotal[ 7],',',$
;                         emstotal[ 8],',',$
;                         emstotal[ 9],',',$
;                         emstotal[10],',',total(emstotal,/double)
                          total(emstotal,/double)


  ; zip up netcdf data files
  print,'zipping up files...'
  spawn,'gzip '+ifp+ems_file1
;  spawn,'gzip '+ifp+ems_file2
;  spawn,'gzip '+ifp+ems_file3


;---- end loop over years

endfor

;---- close ascii file

free_lun, unit
print,'csv file closed.'
print

END

