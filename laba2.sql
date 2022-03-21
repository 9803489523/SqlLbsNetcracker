/*
1.Выбрать клиентов, у которых были заказы в июле 1999 года. Упорядочить по коду
клиента. Использовать внутреннее соединение (inner join) и distinct.
*/

select distinct c.*
  from orders o
       inner join customers c on 
         o.customer_id=c.customer_id and
         o.order_date >= date'1999-07-01' and o.order_date < date'1999-08-01'
  order by c.customer_id
;
         
/*
 2.Выбрать всех клиентов и сумму их заказов за 2000 год, упорядочив их по сумме заказов
(клиенты, у которых вообще не было заказов за 2000 год, вывести в конце), затем по ID
заказчика. Вывести поля: код заказчика, имя заказчика (фамилия + имя через пробел),
сумма заказов за 2000 год. Использовать внешнее соединение (left join) таблицы
заказчиков с подзапросом для выбора суммы товаров (по таблице заказов) по клиентам
за 2000 год (подзапрос с группировкой).
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
3.Выбрать сотрудников, которые работают на первой своей должности (нет записей в
истории). Использовать внешнее соединение (какое конкретно?) с таблицей истории, а
затем отбор записей из таблицы сотрудников таких, для которых не «подцепилось»
строк из таблицы истории. Упорядочить отобранных сотрудников по дате приема на
работу (в обратном порядке, затем по коду сотрудника (в обычном порядке).
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
4.Выбрать все склады, упорядочив их по количеству номенклатуры товаров,
представленных в них. Вывести поля: код склада, название склада, количество
различных товаров на складе. Упорядочить по количеству номенклатуры товаров на
складе (от большего количества к меньшему), затем по коду склада (в обычном
порядке). Склады, для которых нет информации о товарах на складе, вывести в конце.
Подзапросы не использовать.
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
5.Выбрать сотрудников, которые работают в США. Упорядочить по коду сотрудника.
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
6.Выбрать все товары и их описание на русском языке. Вывести поля: код товара,
название товара, цена товара в каталоге (LIST_PRICE), описание товара на русском
языке. Если описания товара на русском языке нет, в поле описания вывести «Нет
описания», воспользовавшись функцией nvl или выражением case (в учебной базе
данных для всех товаров есть описания на русском языке, однако запрос должен быть
написан в предположении, что описания на русском языке может и не быть; для
проверки запроса можно указать код несуществующего языка и проверить, появилось ли
в поле описания соответствующий комментарий). Упорядочить по коду категории
товара, затем по коду товара.
*/

select pi.product_id,
       pi.product_name,
       pi.list_price,
       nvl(pd.translated_description,'нет описания') as translated_description
  from product_information pi 
    left join product_descriptions pd on
      pi.product_id=pd.product_id and
      trim(pd.language_id)='RU'  
  order by pi.category_id,
           pi.product_id
;

/*
7.Выбрать товары, которые никогда не продавались. Вывести поля: код товара, название
товара, цена товара в каталоге (LIST_PRICE), название товара на русском языке (запрос
должен быть написан в предположении, что описания товара на русском языке может и
не быть). Упорядочить по цене товара в обратном порядке (товары, для которых не
указана цена, вывести в конце), затем по коду товара.
*/

select pi.product_id,
       pi.product_name,
       pi.list_price,
       nvl(pd.translated_description,'нет описания') as translated_descriptionce
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
8.Выбрать клиентов, у которых есть заказы на сумму больше, чем в 2 раза превышающую
среднюю цену заказа. Вывести поля: код клиента, название клиента (фамилия + имя
через пробел), количество таких заказов, максимальная сумма заказа. Упорядочить по
количеству таких заказов в обратном порядке, затем по коду клиента.
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
9.Упорядочить клиентов по сумме заказов за 2000 год. Вывести поля: код клиента, имя
клиента (фамилия + имя через пробел), сумма заказов за 2000 год. Упорядочить данные
по сумме заказов за 2000 год в обратном порядке, затем по коду клиента. Клиенты, у
которых не было заказов в 2000, вывести в конце.
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
10.Переписать предыдущий запрос так, чтобы не выводить клиентов, у которых вообще не
было заказов.
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
11.Каждому менеджеру по продажам сопоставить последний его заказ. Менеджера по
продажам считаем сотрудников, код должности которых: «SA_MAN» и «SA_REP».
Вывести поля: код менеджера, имя менеджера (фамилия + имя через пробел), код
клиента, имя клиента (фамилия + имя через пробел), дата заказа, сумма заказа,
количество различных позиций в заказе. Упорядочить данные по дате заказа в обратном
порядке, затем по сумме заказа в обратном порядке, затем по коду сотрудника. Тех
менеджеров, у которых нет заказов, вывести в конце.
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
12.Проверить, были ли заказы, в которых товары поставлялись со скидкой. Считаем, что
скидка была, если сумма заказа меньше суммы стоимости всех позиций в заказе, если
цены товаров смотреть в каталоге (прайсе). Если такие заказы были, то вывести
максимальный процент скидки среди всех таких заказов, округленный до 2 знаков после
запятой.
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
13.Выбрать товары, которые есть только на одном складе. Вывести поля: код товара,
название товара, цена товара по каталогу (LIST_PRICE), код и название склада, на
котором есть данный товар, страна, в которой находится данный склад. Упорядочить
данные по названию стране, затем по коду склада, затем по названию товара.
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
14.Для всех стран вывести количество клиентов, которые находятся в данной стране.
Вывести поля: код страны, название страны, количество клиентов. Для стран, в которых
нет клиентов, в качестве количества клиентов вывести 0. Упорядочить по количеству
клиентов в обратном порядке, затем по названию страны.
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
15.Для каждого клиента выбрать минимальный интервал (количество дней) между его
заказами. Интервал между заказами считать как разницу в днях между датами 2-х
заказов без учета времени заказа. Вывести поля: код клиента, имя клиента
(фамилия + имя через пробел), даты заказов с минимальным интервалом (время не
отбрасывать), интервал в днях между этими заказами. Если у клиента заказов нет или
заказ один за всю историю, то таких клиентов не выводить. Упорядочить по коду
клиента.
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
