;IDL
;-----------------------------------------------------------------------------
;
;
;   CMIP6_biogenic_CO_MAM_2001-2010.pro
;
;
;   This program reads multi-annual MEGAN-MACC biogenic emissions files
;   (with monthly emissions fluxes) and produces a multi-annual (2001-2010) mean
;   emissions data file with 12 monthly emissions fluxes.
;
;
;   Author:    Marcus Koehler
;   Date:      25/08/2017
;   Version:   1.0
;
;
;-----------------------------------------------------------------------------


;------ set file paths and variable names -------------------------------------

; path variables for raw data input files:

workspace = '/group_workspaces/jasmin2/ukca/vol1/mkoehler/emissions/MEGAN-MACC_1980-2010/raw_data/'
ifn = 'MEGAN-MACC_biogenic_CO_1980-2010_66468.nc'

ofn = 'MEGAN-MACC_biogenic_CO_MAM_2001-2010.nc'
surffile = '/home/users/mkoehler/ukca_gws/data/surf_half_by_half_2.nc'

;------ no further changes should be needed below this line -------------------


;---- open biogenic emissions file:

print,'reading emissions data: '
print, ifn

ncid = ncdf_open(workspace+ifn,/nowrite)
timeid = ncdf_varid(ncid,'date')
ncdf_varget,ncid,timeid,times

lonid = ncdf_varid(ncid,'lon')
ncdf_varget,ncid,lonid,lons
latid = ncdf_varid(ncid,'lat')
ncdf_varget,ncid,latid,lats

varid  = ncdf_varid(ncid,'MEGAN_MACC')
ncdf_attget,ncid,varid,'units',varunits
ncdf_varget,ncid,varid,biogflux
ncdf_close,ncid

print,'file closed.'


;---- if required re-order latitudes from S--> N

if (lats[0] > lats[1]) then begin

  print,'re-ordering biogenic emissions field to ascending latitudes...'

  tmpfield = dblarr(n_elements(lons),n_elements(lats),n_elements(times))
  tmplats = fltarr(n_elements(lats))

  for t=0,n_elements(times)-1 do begin
  for k=0,n_elements(lats)-1 do begin
     k_bar = (n_elements(lats)-1)-k   ; k counting up from 0, k_bar counting down from 359
     tmpfield[*,k_bar,t] = biogflux[*,k,t]
  endfor
  endfor

  biogflux = tmpfield

  for k=0,n_elements(lats)-1 do begin   ; do the same for lats as reverse function not available
     k_bar = (n_elements(lats)-1)-k
     tmplats[k_bar] = lats[k]
  endfor

  lats = tmplats

  print,'re-ordering completed.'
  tmpfield = 0b   ; to reduce memory requirements
  tmplats  = 0b

endif


;---- calculate multi-annual averages for each month and extend time series

; the number of elements in array anninc determines the no of years to be
; used for averaging

; timestep increment for the same month of the last 10 years:
anninc=[252,264,276,288,300,312,324,336,348,360]  
; Jan 2001, Jan 2002, Jan 2003, ... , Jan 2010

; annual emissions flux file for years < 1980
meanfld   = dblarr(n_elements(lons),n_elements(lats),12)


for mth=0,11 do begin

  ; calculate average over the last ten years 2001-2010

  for yr=0,n_elements(anninc)-1 do begin
     meanfld[*,*,mth] = meanfld[*,*,mth] + double(biogflux[*,*,mth+anninc[yr]])
  endfor
  meanfld[*,*,mth] = meanfld[*,*,mth] / n_elements(anninc)

endfor


;---- calculate annual total emissions

; read surface area file:
; -179.75 --> 197.75  (0.5 x 0.5 degrees)
; -89.75 --> 89.75
; earth_radius = 6371229.d

ncid=ncdf_open(surffile,/nowrite)
varid = ncdf_varid(ncid,'surf')
ncdf_varget,ncid,varid,surf
ncdf_close,ncid

total_emiss = 0.d
secs_per_month = double(30.*86400.)

for mth = 0,11 do begin
  total_emiss = total_emiss + total(meanfld[*,*,mth]*surf*secs_per_month,/double)
endfor

tot_ems_str = strcompress(string(total_emiss*1.e-9,format='(f6.2)'),/remove_all)+' Tg CO per year (360d_cal)'


;---- write out new emissions fluxes

timeunits='months since 2006-01-01 00:00:00'

outtimes = [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 ]

print,'creating netcdf file: ',ofn
ncid=ncdf_create(ofn,/clobber)

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

fieldvar_id=ncdf_vardef(ncid,'emiss_flux',[londim_id,latdim_id,timedim_id],/double)
ncdf_attput,ncid,fieldvar_id,'units','kg m-2 s-1'
ncdf_attput,ncid,fieldvar_id,'long_name','Biogenic surface CO emissions'
ncdf_attput,ncid,fieldvar_id,'standard_name','tendency_of_atmosphere_mass_content_of_carbon_monoxide_due_to_emission'
ncdf_attput,ncid,fieldvar_id,'molecular_weight',28.01,/float
ncdf_attput,ncid,fieldvar_id,'molecular_weight_units','g mol-1'

ncdf_attput,ncid,/global,'title','Monthly surface emissions of carbon monoxide, calculated using an arithmetic mean of monthly emission fluxes for the years 2001-2010'
ncdf_attput,ncid,/global,'global_annual_total_emissions',tot_ems_str
ncdf_attput,ncid,/global,'source','MEGAN-MACC Biogenic emission inventory - Data between year 1980 and 2010 from MEGAN-MACC distributed by Ether/ECCAD database http://eccad.sedoo.fr'
ncdf_attput,ncid,/global,'reference','Sindelarova et al., Atmos. Chem. Phys., 2014'
ncdf_attput,ncid,/global,'grid','regular 0.5x0.5 degree latitude-longitude grid'
ncdf_attput,ncid,/global,'earth_ellipse','Earth spheric model'
ncdf_attput,ncid,/global,'earth_radius',6371229.0,/float
ncdf_attput,ncid,/global,'history',systime(/utc)+' UTC: CMIP6_biogenic_CO_MAM_2001-2010.pro v1.0'
ncdf_attput,ncid,/global,'institution','Centre for Atmospheric Science, Department of Chemistry, University of Cambridge, U.K.'
ncdf_attput,ncid,/global,'licence','Note specific product user constraints and publication information available from the Ether/ECCAD database http:/eccad.sedoo.fr'

ncdf_control,ncid,/endef

ncdf_varput,ncid,timevar_id,outtimes
ncdf_varput,ncid,lonvar_id,lons
ncdf_varput,ncid,latvar_id,lats
ncdf_varput,ncid,fieldvar_id,meanfld

ncdf_close,ncid

print,'netCDF file closed.'


END
