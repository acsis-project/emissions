;IDL
;-----------------------------------------------------------------------------
;
;
;   make_combined_NVOC_1950-2020.pro
;
;
;   This program reads the pre-processed emissions files with combined
;   sources 1960-2020 and extends the time series to 1950-2020.
;
;   The 12 monthly emissions fluxes of the year 1960 are applied for 
;   all years 1950-1959 and then concatenated with original emissions
;   fluxes of the months of the other years until 2020.
;
;   The time coordinates are the mid-month point according to the respective
;   calendar that is used.
;
;
;-----------------------------------------------------------------------------


;------ set file paths and variable names -------------------------------------


; group workspace:
gws   = '/group_workspaces/jasmin2/ukca/vol1/mkoehler/'
; input file:
ifn   = gws+'emissions/combined_1960-2020/0.5x0.5/combined_sources_CH3OH_1960-2020_greg.nc'
; output file:
ofn   = gws+'emissions/combined_1950-2020/combined_sources_NVOC_1950-2020.nc'

num_years     =  71              ; 71 years 1950-2020
num_months    =  num_years * 12  ; 852 months 1950-2020


;------------------------------------------------------------------------------


;---- read input file

print
print,'reading input data file...'

ncid = ncdf_open(ifn,/nowrite)
lonid = ncdf_varid(ncid,'lon')
ncdf_varget,ncid,lonid,lons
latid = ncdf_varid(ncid,'lat')
ncdf_varget,ncid,latid,lats
varid  = ncdf_varid(ncid,'emiss_flux')
ncdf_attget,ncid,varid,'units',varunits
ncdf_varget,ncid,varid,old_series
ncdf_close,ncid

print,'done.'
print


;---- extend time series

new_series = dblarr(n_elements(lons),n_elements(lats),num_months)

count = 1 
for year=0,9 do begin  ; 1950-1959
   for month=0,11 do begin ;  Jan to Dec

     new_series[*,*,count-1] = old_series[*,*,month]
     count = count+1

   endfor
endfor

new_series[*,*,count-1:num_months-1] = old_series


;---- write out new 1950-2020 emissions flux time series

timeunits='days since 1950-01-01 00:00:00'
outtimes = (findgen(num_months)*30.)+15.


print,'creating netcdf file: ',ofn
ncid=ncdf_create(ofn,/clobber)

timedim_id=ncdf_dimdef(ncid,'time',/unlimited)
londim_id=ncdf_dimdef(ncid,'lon',n_elements(lons))
latdim_id=ncdf_dimdef(ncid,'lat',n_elements(lats))

timevar_id=ncdf_vardef(ncid,'time',timedim_id,/float)
ncdf_attput,ncid,timevar_id,'units',timeunits
ncdf_attput,ncid,timevar_id,'calendar','360_day'
lonvar_id=ncdf_vardef(ncid,'lon',londim_id,/float)
ncdf_attput,ncid,lonvar_id,'name','longitude'
ncdf_attput,ncid,lonvar_id,'units','degrees_east'
latvar_id=ncdf_vardef(ncid,'lat',latdim_id,/float)
ncdf_attput,ncid,latvar_id,'name','latitude'
ncdf_attput,ncid,latvar_id,'units','degrees_north'

fieldvar_id=ncdf_vardef(ncid,'emiss_flux',[londim_id,latdim_id,timedim_id],/double)
ncdf_attput,ncid,fieldvar_id,'units','kg m-2 s-1'
ncdf_attput,ncid,fieldvar_id,'long_name','Surface CH3OH emissions expressed as carbon'
ncdf_attput,ncid,fieldvar_id,'molecular_weight_carbon',12.011,/float
ncdf_attput,ncid,fieldvar_id,'molecular_weight_CH3OH',32.04,/float
ncdf_attput,ncid,fieldvar_id,'molecular_weight_units','g mol-1'

ncdf_attput,ncid,/global,'history','make_combined_NVOC_1950-2020.pro'
ncdf_attput,ncid,/global,'file_creation_date',systime(/utc)+' UTC'
ncdf_attput,ncid,/global,'description','Time-varying monthly surface emissions of methanol (CH3OH) from 1950 to 2020, expressed as carbon.'
ncdf_attput,ncid,/global,'source','The emissions flux in this file comprises combined emissions from anthropogenic, biomass burning, and biogenic sources. MACCity provides anthropogenic emissions from 1960 to 2020 and biomass burning emissions from 1960 to 2008. Biomass burning emissions from 2009 to 2020 have been taken from the ACCMIP linearly interpolated RCP8.5 data set. Biogenic emissions are from MEGAN-MACC 1980-2010. Biogenic emissions 1960-1979 are perpetual averages of 1980-1984. Biogenic emissions 2011-2020 are perpetual averages of 2006-2010. Emissions from 1950-1959 are perpetual 12-monthly emissions of the year 1960.'
ncdf_attput,ncid,/global,'grid','regular 0.5x0.5 degree latitude-longitude grid'
ncdf_attput,ncid,/global,'earth_ellipse','Earth spheric model'
ncdf_attput,ncid,/global,'earth_radius',6371229.d
ncdf_attput,ncid,/global,'global_total_emissions_2000','141.366 Tg CH3OH or 52.994 Tg C per year'

ncdf_control,ncid,/endef

ncdf_varput,ncid,timevar_id,outtimes
ncdf_varput,ncid,lonvar_id,lons
ncdf_varput,ncid,latvar_id,lats
ncdf_varput,ncid,fieldvar_id,new_series

ncdf_close,ncid

print,'netCDF file closed.'


END
