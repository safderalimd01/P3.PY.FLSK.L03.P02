-- stored procedure to get sales dashboard data

delimiter //
DROP PROCEDURE IF EXISTS sproc_sales_dashboard//

delimiter //
CREATE PROCEDURE sproc_sales_dashboard(
IN iparam_start_date date,
IN iparam_end_date date,

OUT oparam_kpi_invoice_count int,
OUT oparam_kpi_client_count int,
OUT oparam_kpi_total_sales_amount int,

OUT oparam_err_flag int,
OUT oparam_err_step varchar(100),
OUT oparam_err_msg varchar(1000))

BEGIN 

/********************************************************************************
-- use this code to test your sales dashboard stored proc:
set @iparam_start_date = '2020-01-01';
set @iparam_end_date = '2020-12-31';
call sproc_sales_dashboard
(@iparam_start_date
,@iparam_end_date
,@oparam_kpi_invoice_count
,@oparam_kpi_client_count
,@oparam_kpi_total_sales_amount
,@oparam_err_flag 
,@oparam_err_step 
,@oparam_err_msg);
select @oparam_kpi_invoice_count, @oparam_kpi_client_count, @oparam_kpi_total_sales_amount
		, @oparam_err_flag, @oparam_err_step, @oparam_err_msg;
**********************************************************************************/ 

-- step 10
-- declare local variables
declare v_step_number decimal(5,2);

-- error handling
DECLARE exit handler for sqlexception , sqlwarning
BEGIN
     
	 ROLLBACK;

	 GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, 
	 @errno = MYSQL_ERRNO, @errtext = MESSAGE_TEXT;

	set oparam_err_flag = 1;

	set oparam_err_step  = concat('error in step: ',v_step_number);

	set oparam_err_msg = @errtext;

END;  


-- step 20
-- initialize variables  
SET v_step_number = 20; 
set oparam_err_flag = 0;

-- step 30
-- get kpi, invoice count
SET v_step_number = 30;
select count(distinct invoice_number)
into oparam_kpi_invoice_count
from sales
where sales_date between iparam_start_date and iparam_end_date
;

-- step 40
-- get kpi, client count
SET v_step_number = 40;
select count(distinct client_id)
into oparam_kpi_client_count
from sales
where sales_date between iparam_start_date and iparam_end_date
;

-- step 50
-- get kpi, total_sales_amount
SET v_step_number = 50;
select sum(row_total)
into oparam_kpi_total_sales_amount
from sales
where sales_date between iparam_start_date and iparam_end_date
;

-- step 60
-- get count by produts, units sold per product
SET v_step_number = 60;
select a.product_id
	,b.product_name
	,sum(a.quantity) as products_sold
from sales a
inner join product b on b.product_id = a.product_id
where a.sales_date between iparam_start_date and iparam_end_date
group by a.product_id
order by products_sold desc
;

-- step 70
-- get amount spend by each customer
SET v_step_number = 70;
select a.client_id
	,b.client_name
	,sum(a.row_total) as client_amount
from sales a
inner join `client` b on b.client_id = a.client_id
where a.sales_date between iparam_start_date and iparam_end_date
group by a.client_id
order by client_amount desc
;

-- step 80
-- sale amount by date
SET v_step_number = 80;
select cast(sales_date as date) as sale_date
	,sum(row_total) as sales_amount
from sales
where sales_date between iparam_start_date and iparam_end_date
group by cast(sales_date as date)

;

END // 
DELIMITER ;

-- use this if u want to provide execute access to other mysql user id
-- GRANT EXECUTE ON PROCEDURE sproc_sales_dashboard to '<my sql user id>';	