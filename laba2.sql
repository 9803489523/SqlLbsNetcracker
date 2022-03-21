/*
1.������� ��������, � ������� ���� ������ � ���� 1999 ����. ����������� �� ����
�������. ������������ ���������� ���������� (inner join) � distinct.
*/

select distinct c.*
  from orders o
       inner join customers c on 
         o.customer_id=c.customer_id and
         o.order_date >= date'1999-07-01' and o.order_date < date'1999-08-01'
  order by c.customer_id
;
         
/*
 2.������� ���� �������� � ����� �� ������� �� 2000 ���, ���������� �� �� ����� �������
(�������, � ������� ������ �� ���� ������� �� 2000 ���, ������� � �����), ����� �� ID
���������. ������� ����: ��� ���������, ��� ��������� (������� + ��� ����� ������),
����� ������� �� 2000 ���. ������������ ������� ���������� (left join) �������
���������� � ����������� ��� ������ ����� ������� (�� ������� �������) �� ��������
�� 2000 ��� (��������� � ������������).
*/

select c.customer_id,
       c.cust_last_name||' '||c.cust_first_name as name,
       b.sum_of_orders
  from customers c
    left join (
                select  o.customer_id,
                        sum(o.order_total) as sum_of_orders
                  from orders o
                  where o.order_date >= date'2000-01-01' and 
                        o.order_date < date'2001-01-01' 
                  group by o.customer_id
              ) b on c.customer_id=b.customer_id
  order by b.sum_of_orders desc nulls last,
           c.customer_id
;
/*
3.������� �����������, ������� �������� �� ������ ����� ��������� (��� ������� �
�������). ������������ ������� ���������� (����� ���������?) � �������� �������, �
����� ����� ������� �� ������� ����������� �����, ��� ������� �� �������������
����� �� ������� �������. ����������� ���������� ����������� �� ���� ������ ��
������ (� �������� �������, ����� �� ���� ���������� (� ������� �������).
*/

select e.*
  from employees e
       left join job_history j on
         e.employee_id=j.employee_id
  where j.employee_id is null
  order by e.hire_date desc,
           e.employee_id 
;

/*
4.������� ��� ������, ���������� �� �� ���������� ������������ �������,
�������������� � ���. ������� ����: ��� ������, �������� ������, ����������
��������� ������� �� ������. ����������� �� ���������� ������������ ������� ��
������ (�� �������� ���������� � ��������), ����� �� ���� ������ (� �������
�������). ������, ��� ������� ��� ���������� � ������� �� ������, ������� � �����.
���������� �� ������������.
*/

select w.warehouse_id,
       w.warehouse_name,
       count(i.quantity_on_hand) as products_count
  from warehouses w
       left join inventories i on
         w.warehouse_id = i.warehouse_id
  group by w.warehouse_id, w.warehouse_name
  order by count(i.quantity_on_hand) desc
           nulls last
;

/*
5.������� �����������, ������� �������� � ���. ����������� �� ���� ����������.
*/

select e.*
  from employees e
       left join departments d on
                 d.department_id=e.department_id
       left join locations l on
                 l.location_id=d.location_id
       inner join countries c on
                 c.country_id=l.country_id and
                 trim(lower(c.country_id))='us'
  order by e.employee_id         
;

/*
6.������� ��� ������ � �� �������� �� ������� �����. ������� ����: ��� ������,
�������� ������, ���� ������ � �������� (LIST_PRICE), �������� ������ �� �������
�����. ���� �������� ������ �� ������� ����� ���, � ���� �������� ������� ����
���������, ���������������� �������� nvl ��� ���������� case (� ������� ����
������ ��� ���� ������� ���� �������� �� ������� �����, ������ ������ ������ ����
������� � �������������, ��� �������� �� ������� ����� ����� � �� ����; ���
�������� ������� ����� ������� ��� ��������������� ����� � ���������, ��������� ��
� ���� �������� ��������������� �����������). ����������� �� ���� ���������
������, ����� �� ���� ������.
*/

select pi.product_id,
       pi.product_name,
       pi.list_price,
       nvl(pd.translated_description,'��� ��������') as translated_description
  from product_information pi 
    left join product_descriptions pd on
      pi.product_id=pd.product_id and
      trim(pd.language_id)='RU'  
  order by pi.category_id,
           pi.product_id
;

/*
7.������� ������, ������� ������� �� �����������. ������� ����: ��� ������, ��������
������, ���� ������ � �������� (LIST_PRICE), �������� ������ �� ������� ����� (������
������ ���� ������� � �������������, ��� �������� ������ �� ������� ����� ����� �
�� ����). ����������� �� ���� ������ � �������� ������� (������, ��� ������� ��
������� ����, ������� � �����), ����� �� ���� ������.
*/

select pi.product_id,
       pi.product_name,
       pi.list_price,
       nvl(pd.translated_description,'��� ��������') as translated_descriptionce
  from product_information pi
       left join product_descriptions pd on
         pi.product_id=pd.product_id and
         trim(pd.language_id)='RU'
       left join order_items o on
         pi.product_id=o.product_id
  where o.quantity is null
    order by pi.list_price desc nulls last,
             pi.product_id            
;

/*
8.������� ��������, � ������� ���� ������ �� ����� ������, ��� � 2 ���� �����������
������� ���� ������. ������� ����: ��� �������, �������� ������� (������� + ���
����� ������), ���������� ����� �������, ������������ ����� ������. ����������� ��
���������� ����� ������� � �������� �������, ����� �� ���� �������.
*/

select c.customer_id,
       c.cust_last_name||' '|| c.cust_first_name as name,
       count(*) as large_sum_orders_count,
       max(o.order_total) as max
  from customers c 
    inner join orders o on o.customer_id=c.customer_id
  where o.order_total > 2*(
                          select avg(o.order_total)
                          from orders o
                        )
  group by c.customer_id,
           c.cust_last_name,
           c.cust_first_name
  order by count(*) desc,
           c.customer_id
;

/*
9.����������� �������� �� ����� ������� �� 2000 ���. ������� ����: ��� �������, ���
������� (������� + ��� ����� ������), ����� ������� �� 2000 ���. ����������� ������
�� ����� ������� �� 2000 ��� � �������� �������, ����� �� ���� �������. �������, �
������� �� ���� ������� � 2000, ������� � �����.
*/

select c.customer_id,
       c.cust_last_name||' '|| c.cust_first_name as name,
       sum(o.order_total) as orders_sum
  from customers c
    left join orders o on
      o.customer_id=c.customer_id and
      o.order_date >= date'2000-01-01' and o.order_date < date'2001-01-01'
  group by c.customer_id,
           c.cust_last_name,
           c.cust_first_name
  order by sum(o.order_total) desc nulls last,
           c.customer_id 
;

/*
10.���������� ���������� ������ ���, ����� �� �������� ��������, � ������� ������ ��
���� �������.
*/

select c.customer_id,
       c.cust_last_name||' '|| c.cust_first_name as name,
       sum(o.order_total) as orders_sum
  from customers c
    join orders o on
      o.customer_id=c.customer_id and
      o.order_date >= date'2000-01-01' and  o.order_date < date'2001-01-01'
  group by c.customer_id,
           c.cust_last_name,
           c.cust_first_name
  order by sum(o.order_total) desc nulls last,
           c.customer_id 
;

/*
11.������� ��������� �� �������� ����������� ��������� ��� �����. ��������� ��
�������� ������� �����������, ��� ��������� �������: �SA_MAN� � �SA_REP�.
������� ����: ��� ���������, ��� ��������� (������� + ��� ����� ������), ���
�������, ��� ������� (������� + ��� ����� ������), ���� ������, ����� ������,
���������� ��������� ������� � ������. ����������� ������ �� ���� ������ � ��������
�������, ����� �� ����� ������ � �������� �������, ����� �� ���� ����������. ���
����������, � ������� ��� �������, ������� � �����.
*/
  
select e.employee_id,
       e.last_name||' '||e.first_name as emp_name,
       c.customer_id,
       c.cust_last_name||' '||c.cust_first_name as cust_name,
       a.max_order_date as order_date,
       o.order_total,
       (
         select count(*)
           from order_items oi
           where oi.order_id=o.order_id
           group by oi.order_id
       ) as order_line_items
  from employees e
    left join (
                select o.sales_rep_id,
                       max(o.order_date) max_order_date    
                  from orders o
                  group by o.sales_rep_id
              ) a
      on e.employee_id=a.sales_rep_id
        left join orders o 
          on o.sales_rep_id=a.sales_rep_id and
             a.max_order_date=o.order_date
            left join customers c
              on c.customer_id=o.customer_id
  where e.job_id='SA_MAN' or 
        e.job_id='SA_REP'
  order by a.max_order_date desc nulls last,
            o.order_total,
            e.employee_id
;   


/*
12.���������, ���� �� ������, � ������� ������ ������������ �� �������. �������, ���
������ ����, ���� ����� ������ ������ ����� ��������� ���� ������� � ������, ����
���� ������� �������� � �������� (������). ���� ����� ������ ����, �� �������
������������ ������� ������ ����� ���� ����� �������, ����������� �� 2 ������ �����
�������.
*/

select max((
            select round((discount.sum_price-ord.order_total)/discount.sum_price*100,2)
              from orders ord
              where ord.order_id=discount.order_id
        )) as max_discount_percent
  from (
          select sum(pi.list_price*oi.quantity) as sum_price,
                 o.order_id
            from orders o
              join order_items oi
                   on o.order_id=oi.order_id
              join product_information pi
                   on pi.product_id=oi.product_id
            group by o.order_id        
        ) discount
;
  
/*
13.������� ������, ������� ���� ������ �� ����� ������. ������� ����: ��� ������,
�������� ������, ���� ������ �� �������� (LIST_PRICE), ��� � �������� ������, ��
������� ���� ������ �����, ������, � ������� ��������� ������ �����. �����������
������ �� �������� ������, ����� �� ���� ������, ����� �� �������� ������.
*/

select pi.product_id,
       pi.product_name,
       pi.list_price,
       w.warehouse_id,
       w.warehouse_name,
       c.country_name       
  from product_information pi
         join inventories i 
           on pi.product_id=i.product_id
             join warehouses w
               on i.warehouse_id=w.warehouse_id
                 join locations l
                   on w.location_id=l.location_id
                     join countries c
                       on l.country_id=c.country_id
  where exists(
                select prinf.product_id
                  from product_information prinf
                    join inventories inv
                      on prinf.product_id=inv.product_id
                  where pi.product_id=prinf.product_id
                  group by prinf.product_id
                  having count(inv.warehouse_id)=1
              )
  order by c.country_name,
           w.warehouse_id,
           pi.product_name
;
/*
14.��� ���� ����� ������� ���������� ��������, ������� ��������� � ������ ������.
������� ����: ��� ������, �������� ������, ���������� ��������. ��� �����, � �������
��� ��������, � �������� ���������� �������� ������� 0. ����������� �� ����������
�������� � �������� �������, ����� �� �������� ������.
*/

select co.country_id,
       co.country_name,
       nvl((
          select count(c.customer_id)
            from customers c
            where c.cust_address_country_id=co.country_id
            group by c.cust_address_country_id
       ) ,0) as number_of_customers
  from countries co
  order by number_of_customers desc,
           co.country_id         
;

select avg(o.order_total)
  from orders o
  ;

/*
15.��� ������� ������� ������� ����������� �������� (���������� ����) ����� ���
��������. �������� ����� �������� ������� ��� ������� � ���� ����� ������ 2-�
������� ��� ����� ������� ������. ������� ����: ��� �������, ��� �������
(������� + ��� ����� ������), ���� ������� � ����������� ���������� (����� ��
�����������), �������� � ���� ����� ����� ��������. ���� � ������� ������� ��� ���
����� ���� �� ��� �������, �� ����� �������� �� ��������. ����������� �� ����
�������.
*/

select c.customer_id,
       c.cust_last_name||' '||c.cust_first_name as cust_name,
       t.first_date,
       t.last_date,
       t.min_date as min_orders_interval
  from customers c
    join (
            select o1.customer_id,
                   o1.order_date as first_date,
                   o2.order_date as last_date,
                   md.min_date
              from orders o1
                join orders o2
                  on o1.customer_id=o2.customer_id and
                     o2.order_date>o1.order_date  
                    join (
                            select o3.customer_id,
                                   min(
                                        case
                                          when o3.customer_id=o4.customer_id and o4.order_date>o3.order_date then
                                               trunc(o4.order_date,'dd')-trunc(o3.order_date,'dd')
                                        end
                                        ) as min_date
                              from orders o3
                                join orders o4
                                  on o3.customer_id=o4.customer_id and
                                     o4.order_date>o3.order_date
                              group by o3.customer_id
                          ) md
                      on md.customer_id=o2.customer_id and
                         md.min_date=trunc(o2.order_date,'dd')-trunc(o1.order_date,'dd')         
                  
          ) t 
              on t.customer_id=c.customer_id
;
