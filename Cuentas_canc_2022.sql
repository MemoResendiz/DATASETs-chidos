select 
delim.cuenta,
delim.status,
modems.cuenta,
modems.model_ont

from (
select 
account_no as cuenta,
status,created_t,
vida_util,anio_created,
mes_created,status_cuenta,cancel_t,
anio_cancel,mes_cancel from (

SELECT *, case
       when status='10100' or status='10102' then 0
       else (CAST(SUBSTRING(cancel_t,1,4) as int))
       end as anio_cancel, case
       when status='10100' or status='10102' then 0
       else (CAST(SUBSTRING(cancel_t,6,2) as int))       
       end as mes_cancel FROM(
SELECT account_no, status,created_t,vida_util, (CAST(SUBSTRING(created_t,1,4) as int)) as anio_created, (CAST(SUBSTRING(created_t,6,2) as int)) as mes_created, status_cuenta,
 (DATEADD(month, vida_util ,date(created_t))) AS cancel_t FROM(
  select 
     account_no,
     status,created_t,
     case when status = '10103' then DATEDIFF(MM , date(created_t), date(from_unixtime(last_status_t)))
           when status='10102'  then DATEDIFF(MM , date(created_t), CURRENT_DATE ) 
           when status='10100' then DATEDIFF(MM , date(created_t), CURRENT_DATE ) 
      end as vida_util,
    
      case when status='10100'
        then 'Activo'
        When status='10102'
        then 'Inactivo'
        when status='10103'
        then 'Cancelada'
  end as status_cuenta
  from data_staging.brm_account_t where info_day= 20221226)
  
WHERE SUBSTRING(account_no,1,2) = '1.' OR SUBSTRING(account_no,1,3) IN ('010','011'))

) 
where anio_cancel = 2022) as delim

left join (

SELECT cuenta,
       model_ont,
       CASE
         WHEN model_ont IN ('HG8045H','HG8247','HG8245','ZTEG-824X') THEN 'antiguo'
         WHEN model_ont IN ('HG8245H','ZTEG-F660','FH-AN55060','AN5506-04-F') THEN 'seminuevo'
         WHEN model_ont IN ('HG8145V5','F660V7.0','F670LV9.0','F670LV9.0B','HG6145F','ZTEG-F670','HG8145X6') THEN 'nuevo'
       END AS p_model_ont,
       version_fm,
       vendor_ont 
     FROM bi.cta_model_ont
WHERE info_day = (SELECT MAX(info_day) FROM bi.cta_model_ont)
and p_model_ont is not null) as modems

on delim.cuenta=modems.cuenta
--where modems.cuenta is not null
limit 100;
