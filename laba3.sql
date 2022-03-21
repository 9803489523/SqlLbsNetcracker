/*
  1.Выбрать с помощью иерархического запроса сотрудников 3-его уровня иерархии (т.е.
таких, у которых непосредственный начальник напрямую подчиняется руководителю
организации). Упорядочить по коду сотрудника.
*/
select * 
  from employees e
  where level=3
  connect by prior e.employee_id=e.manager_id
  order siblings by e.employee_id
;
/*
  2.Для каждого сотрудника выбрать всех его начальников по иерархии. Вывести поля: код
сотрудника, имя сотрудника (фамилия + имя через пробел), код начальника, имя
начальника (фамилия + имя через пробел), кол-во промежуточных начальников между
сотрудником и начальником из данной строки выборки. Если у какого-то сотрудника
есть несколько начальников, то для данного сотрудника в выборке должно быть
несколько строк с разными начальниками. Упорядочить по коду сотрудника, затем по
уровню начальника (первый – непосредственный начальник, последний – руководитель
организации).
*/
select 
      connect_by_root(e.employee_id) as emp_id,
      connect_by_root(e.first_name||' '||e.last_name) as emp_name,
      e.employee_id as boss_id,
      e.first_name||' '||e.last_name as boss_name,
      level-2 as ierarhy
  from employees e
  where level>1
  connect by prior e.employee_id=e.manager_id
  order siblings by e.employee_id
;
/*
3.Для каждого сотрудника посчитать количество его подчиненных, как непосредственных,
так и по иерархии. Вывести поля: код сотрудника, имя сотрудника (фамилия + имя через
пробел), общее кол-во подчиненных.
*/
select 
      e.employee_id as emp_id,
      e.first_name||' '||e.last_name as emp_name,
      count(connect_by_root(e.employee_id)) as emp_number
  from employees e
  where level>1
  connect by  e.employee_id= prior e.manager_id
  group by e.employee_id,
           e.first_name,
           e.last_name
  order  by e.employee_id desc
;

/*
4.Для каждого заказчика выбрать в виде строки через запятую даты его заказов. Для
конкатенации дат заказов использовать sys_connect_by_path (иерархический запрос). Для
отбора «последних» строк использовать connect_by_isleaf.
*/
select d.customer_id,
       sys_connect_by_path(d.second_date, ', ') as dates
  from(
        select o.customer_id,
                  lead(o.order_date) over (
                    partition by o.customer_id
                    order by o.order_date
                  ) as first_date,
               o.order_date as second_date
            from orders o
            group by o.customer_id,
                    o.order_date
      ) d
  where connect_by_isleaf = 1
  
  connect by d.customer_id = prior d.customer_id and
             d.first_date = prior d.second_date
  start with d.first_date is null
;

/*
5.Выполнить задание No 4 c помощью обычного запроса с группировкой и функцией
listagg.
*/
select o.customer_id,
       listagg(o.order_date,', ') within group(order by o.customer_id) as dates
  from orders o
  group by o.customer_id
;
/*
6.Выполнить задание No 2 с помощью рекурсивного запроса.
*/

with t_rec(employee_id, emp_name, manager_id, man_name, prev_man_id, man_level) as (
  select e.employee_id,
         e.first_name || ' ' || e.last_name,
         e.employee_id,
         e.first_name || ' ' || e.last_name,
         e.manager_id,
          0
    from  employees e
  union all
  select prev.employee_id,
         prev.emp_name,
         curr.employee_id,
         curr.first_name || ' ' || curr.last_name,
         curr.manager_id,
         man_level + 1
    from t_rec prev
         join employees curr on
           curr.employee_id = prev.prev_man_id
)
select tr.employee_id,
       tr.emp_name, 
       tr.manager_id, 
       tr.man_name, 
       tr.man_level - 1 as man_level
  from t_rec tr
  where man_level > 0
  order by  tr.employee_id,
            tr.man_level
;
/*
7.Выполнить задание No 3 с помощью рекурсивного запроса.
*/
with t_req(manager_id, man_name, employee_id) as (
  select e.employee_id,
         e.last_name || ' ' || e.first_name,
         e.employee_id
    from employees e
  union all
  select prev.manager_id,
         prev.man_name,
         curr.employee_id
    from t_req prev
         join  employees curr
           on curr.manager_id=prev.employee_id
)
select r.manager_id,
       r.man_name,
       count(*)-1 as emp_number
  from t_req r
  group by r.manager_id,
           r.man_name
  order by emp_number desc
;

/*
8.Каждому менеджеру по продажам сопоставить последний его заказ. Менеджером по
продажам считаем сотрудников, код должности которых: «SA_MAN» и «SA_REP». Для
выборки последних заказов по менеджерам использовать подзапрос с применением
аналитических функций (например в подзапросе выбирать дату следующего заказа
менеджера, а во внешнем запросе «оставить» только те строки, у которых следующего
заказа нет). Вывести поля: код менеджера, имя менеджера (фамилия + имя через
пробел), код клиента, имя клиента (фамилия + имя через пробел), дата заказа, сумма
заказа, количество различных позиций в заказе. Упорядочить данные по дате заказа в
обратном порядке, затем по сумме заказа в обратном порядке, затем по коду сотрудника.
Тех менеджеров, у которых нет заказов, вывести в конце.
*/
select e.employee_id,
       e.first_name || ' ' || e.last_name as employee_name,
       c.customer_id,
       c.cust_first_name || ' ' || c.cust_last_name as customer_name,
       o.order_date,
       o.order_total,
      (
        select  count(oi.product_id)
          from  order_items oi
          where oi.order_id = o.order_id
      ) as amount_of_items
  from  employees e
        left join (
          select o.*,
                 lead(o.order_date) over(
                  partition by o.sales_rep_id
                  order by o.order_date
                  ) as next_order
            from orders o
        ) o on
          o.sales_rep_id = e.employee_id and
          o.next_order is null
        left join customers c on
          c.customer_id = o.customer_id          
  where e.job_id in ('SA_MAN', 'SA_REP')
  order by o.order_date desc nulls last,
           o.order_total desc nulls last,
           e.employee_id
;
/*
9.Для каждого месяца текущего года найти первые и последние рабочие и выходные дни с
учетом праздников и переносов выходных дней (на 2016 год эту информацию можно
посмотреть, например, на странице http://www.interfax.ru/russia/469373). Для
формирования списка всех дней текущего года использовать иерархический запрос,
оформленный в виде подзапроса в секции with. Праздничные дни и переносы выходных
также задать в виде подзапроса в секции with (с помощью union all перечислить все
даты, в которых рабочие/выходные дни не совпадают с обычной логикой определения
выходного дня как субботы и воскресения). Запрос должен корректно работать, если
добавить изменить какие угодно выходные/рабочие дни в данном подзапросе. Вывести
поля: месяц в виде первого числа месяца, первый выходной день месяца, последний
выходной день, первый праздничный день, последний праздничный день.
Задачи на манипулирование данными. (После выполнения запросов транзакции
завершать необязательно, чтобы исходные данные не поменялись).
*/
with 
days as
(
  select  trunc(sysdate, 'yyyy') + level - 1 as data
    from  dual
    connect by  trunc(sysdate, 'yyyy') + level - 1 <
                  add_months(trunc(sysdate, 'yyyy'), 12)
),
weekends as 
(
  select date'2018-01-01' as data, 1 as type from dual union all
  select date'2018-01-02', 1 from dual union all
  select date'2018-01-03', 1 from dual union all
  select date'2018-01-04', 1 from dual union all
  select date'2018-01-05', 1 from dual union all
  select date'2018-01-08', 1 from dual union all
  select date'2018-02-23', 1 from dual union all
  select date'2018-03-08', 1 from dual union all
  select date'2018-03-09', 1 from dual union all
  select date'2018-04-28', 0 from dual union all
  select date'2018-04-30', 1 from dual union all
  select date'2018-05-01', 1 from dual union all
  select date'2018-05-02', 1 from dual union all
  select date'2018-05-09', 1 from dual union all
  select date'2018-06-09', 0 from dual union all
  select date'2018-06-11', 1 from dual union all
  select date'2018-06-12', 1 from dual union all
  select date'2018-11-05', 1 from dual union all
  select date'2018-12-29', 0 from dual union all
  select date'2018-12-31', 1 from dual
)
select trunc(d.data, 'MM') as data, 
        min(
          case when d.type = 0 then d.data
          end
        ) as first_working_day,
        max(
          case when d.type = 0 then d.data
          end
        ) as last_working_day,
        min(
          case when d.type = 1 then d.data
          end
        ) as first_weekend,
        max(
          case when d.type = 1 then d.data
          end
        ) as last_weekend
       
  from (
          select  d.data,
                  nvl(
                    w.type, 
                    case 
                      when to_char(d.data, 'Dy', 'nls_date_language=english') in ('Sat', 'Sun') then 1
                      else 0
                    end
                  ) as type
            from  days d
                  left join weekends w on
                    w.data = d.data
      ) d
  group by  trunc(d.data, 'MM')
  order by  data
;
/*
10.3-м самых эффективным по сумме заказов за 1999 год менеджерам по продажам
увеличить зарплату еще на 20%.
*/
update employees e
  set e.salary = e.salary+e.salary*0.2
  where e.employee_id in (
          select  emp.employee_id
            from (
                   select e.employee_id,
                         order_total_sum
                    from  employees e
                        join (
                            select o.sales_rep_id,
                                   sum(o.order_total) as order_total_sum
                              from orders o
                              where  o.order_date between date'1999-01-01' and  date'2000-01-01'
                              group by  o.sales_rep_id
                            ) o on
                              o.sales_rep_id = e.employee_id
                      where e.job_id in('SA_MAN', 'SA_REP')
                      order by order_total_sum desc
                  ) emp
            where rownum <= 3
        )
;

select e.employee_id,
       order_total_sum,
       e.salary
  from employees e
       join (
              select  o.sales_rep_id,
                  sum(o.order_total) as order_total_sum
                from  orders o
                where o.order_date between date'1999-01-01'  and date'2000-01-01'
                group by  o.sales_rep_id
        ) o on o.sales_rep_id = e.employee_id
  order by order_total_sum desc
;

/*
11.Завести нового клиента ‘Старый клиент’ с менеджером, который является
руководителем организации. Остальные поля клиента – по умолчанию.
*/
insert into customers (cust_first_name, cust_last_name, account_mgr_id)
select 'Cтарый',
       'клиент',
       e.employee_id
  from employees e
  where e.manager_id is null
;

select c.*
  from customers c
  where c.cust_first_name = 'Cтарый'
;

/*
12.Для клиента, созданного в предыдущем запросе, (найти можно по максимальному id
клиента), продублировать заказы всех клиентов за 1990 год. (Здесь будет 2 запроса, для
дублирования заказов и для дублирования позиций заказа).
*/
insert into orders (order_date, order_mode, customer_id, order_status, order_total, sales_rep_id, promotion_id)
select o.order_date,
       o.order_mode,
       (
        select max(c.customer_id) as cust_id
          from customers c
       ) as cust_id,
        o.order_status,
        o.order_total,
        o.sales_rep_id,
        o.promotion_id
  from  orders o
  where o.order_date between date'1990-01-01' and date'1991-01-01'
;

insert  into order_items (order_id, line_item_id, product_id, unit_price, quantity)
select  o2.order_id,
        oi.line_item_id,
        oi.product_id,
        oi.unit_price,
        oi.quantity
  from  order_items oi
        join orders o1 on
          o1.order_id = oi.order_id
        join orders o2 on
         o2.order_date = o1.order_date and
          o2.customer_id = (
            select  max(c.customer_id) as customer_id
              from  customers c
          )
  where o1.order_date between date'1990-01-01'and date'1991-01-01'
;
/*
13.Для каждого клиента удалить самый первый заказ. Должно быть 2 запроса: первый – для
удаления позиций в заказах, второй – на удаление собственно заказов).
*/
delete from order_items oi
  where oi.order_id in (
        select o.order_id
          from orders o
            join (
              select o.customer_id,
                     min(o.order_date) as order1_date
                from  orders o
                group by  o.customer_id
                  ) o1 on o1.customer_id = o.customer_id and
                          o1.order1_date = o.order_date
                        )
;

delete from orders o
  where o.order_id in (
    select o.order_id
      from orders o
        join (
              select o.customer_id,
                     min(o.order_date) as order1_date
                from orders o
                group by  o.customer_id
              ) o1 on o1.customer_id = o.customer_id and
                         o1.order1_date = o.order_date
                       )
;
/*
14.Для товаров, по которым не было ни одного заказа, уменьшить цену в 2 раза (округлив
до целых) и изменить название, приписав префикс ‘Супер Цена! ’.
*/
update product_information pi
  set pi.product_name='Супер Цена! '||pi.product_name,
      pi.list_price=round(pi.list_price / 2),
      pi.min_price=round(pi.min_price/2)
  where not exists (
          select oi.*
            from order_items oi
            where oi.product_id = pi.product_id
        )
  ;
/*
15.Импортировать в базу данных из прайс-листа фирмы «Рет» (http://www.voronezh.ret.ru/?
&pn=down) информацию о всех реализуемых планшетах. Подсказка: воспользоваться
excel для конструирования insert-запросов (или select-запросов, что даже удобнее).
*/
insert  into product_information (product_description, list_price, min_price, warranty_period)
select  trim(product_description) as product_description,
        list_price,
        min_price, 
        warranty_period
  from
  (
    select '	Ноутбук 11" Prestigio Smartbook 116C (LWPSB116C01BFHBKCIS), Atom Z8350 1.44 2GB 32GB SSD 1920*1080 IPS USB2.0 WiFi BT miniHDMI SD 1 кг W10 чёрный	 ' as product_description, 	9990,00	 as list_price,	9990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 12" Lenovo ThinkPad X220, Core i5-2520M 2.5 8GB 128GB SSD 1366*768 3*USB2.0 LAN WiFi DP/VGA камера SD 1.5кг W7P черный, восстановленный	 ' as product_description, 	22990,00	 as list_price,	22990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 13" ASUS ZENBOOK UX310UA-FC647T, Core i3-7100U 2.4 4GB 1Тб 1920*1080 IPS iHD520 2*USB2.0/USB3.0 USB-C WiFi BT HDMI камера SD 1.45кг W10 серый	 ' as product_description, 	48225,00	 as list_price,	48225,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 13" ASUS ZENBOOK UX310UQ-FC559T, Core i3-7100U 2.4 6GB 256GB SSD 1920*1080 IPS GT940MX 2GB iHD520 2*USB2.0/USB3.0 USB-C WiFi BT HDMI камера SD 1.45кг W10 серый	 ' as product_description, 	50337,00	 as list_price,	50337,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 14" ASUS X441BA-GA114T, AMD A6-9220 2.5 4GB 1TB Radeon R4 DVD-RW USB2.0/USB3.0 USB-C LAN WiFi BT HDMI камера SD 1.75кг W10 чёрный-золотистый	 ' as product_description, 	23919,00	 as list_price,	23919,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 14" HP 14-am006ur (W7S20EA), Celeron N3060 1.6 2GB 32GB SSD 2USB2.0/USB3.0 LAN WiFi BT HDMI/VGA камера SD 1.7кг W10 черный	 ' as product_description, 	16793,00	 as list_price,	16793,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 14" HP 14-bp006ur (1ZJ39EA), Pentium N3710 1.6 4GB 500GB USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 1.55кг DOS черный	 ' as product_description, 	25255,00	 as list_price,	25255,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 14" HP 14-bp007ur (1ZJ40EA), Pentium N3710 1.6 4GB 500GB USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.04кг W10 черный	 ' as product_description, 	29417,00	 as list_price,	29417,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 14" HP 14-bp008ur (1ZJ41EA), Core i3-6006U 2.0 4GB 500GB 2*USB3.0 USB-C LAN WiFi BT HDMI камера SD 1.58кг W10 черный	 ' as product_description, 	32612,00	 as list_price,	32612,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 14" HP 14-bs010ur (1ZJ55EA), Pentium N3710 1.6 4GB 500GB USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.04кг W10 синий	 ' as product_description, 	25954,00	 as list_price,	25954,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 14" HP 14-bs012ur (1ZJ57EA), Pentium N3710 1.6 4GB 500GB USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.04кг W10 белый	 ' as product_description, 	26775,00	 as list_price,	26775,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 14" HP 14-bs013ur (1ZJ58EA), Pentium N3710 1.6 4GB 500GB USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.04кг W10 серый	 ' as product_description, 	27889,00	 as list_price,	27889,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 14" Prestigio Smartbook 141C, Atom Z8350 1.44 2GB 32GB SSD 1920*1080 USB2.0/USB3.0 WiFi BT miniHDMI SD 1.45 кг W10 черный	 ' as product_description, 	12990,00	 as list_price,	12990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS A553SA-XX307T, Celeron N3050 1.6 2GB 500GB USB2.0/USB3.0 LAN WiFi BT HDMI/VGA камера SD 1.9кг W10 черный	 ' as product_description, 	18207,00	 as list_price,	18207,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS FX503VD-E4234T, Core i5-7300HQ 2.5 8GB 1Тб 1920*1080 IPS GTX1050 2GB USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.53кг W10 черный	 ' as product_description, 	59076,00	 as list_price,	59076,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS FX504GD-E41075, Core i7-8750H 2.2 8GB 1Тб 1920*1080 IPS GTX1050 4GB USB3.0/USB2.0 LAN WiFi BT HDMI камера SD DOS черный	 ' as product_description, 	75684,00	 as list_price,	75684,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS K501UX-DM282T, Core i7-6500U 2.5 8GB 1Тб 1920*1080 GTX950M 2GB 2USB3.0/2USB2.0 LAN WiFi BT HDMI камера SD/SDHC/SDXC 2кг W10 черный	 ' as product_description, 	59119,00	 as list_price,	59119,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS N580GD-DM243T, Core i5-8300H 2.3 8GB 1Тб+128GB SSD 1920*1080 IPS GTX1050 2GB 2*USB2.0/USB3.0 USB-C LAN WiFi BT HDMI камера SD 1.99кг W10 золотистый	 ' as product_description, 	67848,00	 as list_price,	67848,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS N580VD-DM194T, Core i5-7300HQ 2.5 8GB 1Тб 1920*1080 IPS GTX1050 2GB 2*USB2.0/USB3.0 USB-C LAN WiFi BT HDMI камера SD 1.99кг W10 золотистый	 ' as product_description, 	59119,00	 as list_price,	59119,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS R540SA-XX587T, Celeron N3060 1.6 2GB 500GB USB2.0/USB3.0 USB-C LAN WiFi BT HDMI камера SD 2.1кг W10 черный-золотистый	 ' as product_description, 	17564,00	 as list_price,	17564,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS R541NA-GQ418T, Celeron N3350 1.1 4GB 500GB USB2.0/USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD 2.1кг W10 черный-золотистый	 ' as product_description, 	20278,00	 as list_price,	20278,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS S510UN-BQ219T, Core i5-8250U 1.6 6GB 1Тб 1920*1080 IPS MX150 2GB 2*USB2.0/USB3.0 USB-C WiFi BT HDMI камера SD 1.7кг W10 серый	 ' as product_description, 	53193,00	 as list_price,	53193,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS S510UN-BQ442T, Core i5-8250U 1.6 6GB 500GB+128GB SSD 1920*1080 IPS MX150 2GB 2*USB2.0/USB3.0 USB-C LAN WiFi BT HDMI камера SD 1.7кг W10 серый	 ' as product_description, 	56977,00	 as list_price,	56977,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X507MA-EJ012, Pentium N5000 1.1 4GB 1Тб USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 1.75кг DOS серый	 ' as product_description, 	23562,00	 as list_price,	23562,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X507UA-BQ040, Core i3-6006U 2.0 4GB 1Тб USB2.0/USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD 2кг Linux серый	 ' as product_description, 	28863,00	 as list_price,	28863,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X507UB-BQ362T, Core i3-8130U 2.2 6GB 1Тб 1920*1080 GT110MX 2GB 2*USB2.0/USB3.0 USB-C LAN WiFi BT HDMI камера SD 1.8кг W10 серый	 ' as product_description, 	43911,00	 as list_price,	43911,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X507UB-EJ043, Core i3-6006U 2.0 4GB 1Тб GF MX110 2GB USB3.0/USB2.0 USB-C LAN WiFi BT HDMI/VGA камера SD 2.04кг DOS серый	 ' as product_description, 	28203,00	 as list_price,	28203,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540LA-DM1082T, Core i3-5005U 2.0 4GB 500GB 1920*1080 USB2.0/USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD 1.75кг W10 черный-золотистый	 ' as product_description, 	32273,00	 as list_price,	32273,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540LA-DM1255, Core i3-5005U 2.0 4GB 500GB 1920*1080 DVD-RW USB2.0/USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD 2кг DOS золотистый-черный	 ' as product_description, 	28917,00	 as list_price,	28917,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540LA-XX360T, Core i3-5005U 2.0 4GB 500GB USB2.0/USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD 2кг W10 золотистый-черный	 ' as product_description, 	27489,00	 as list_price,	27489,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540MA-GQ120T, Pentium N5000 1.1 4GB 500GB 2*USB2.0/USB3.0 WiFi BT HDMI камера SD 2кг W10 черный-золотистый	 ' as product_description, 	24133,00	 as list_price,	24133,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540MB-GQ079, Pentium N5000 1.1 4GB 500GB MX110 2GB DVD-RW 2*USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 1.9кг DOS черный-золотистый	 ' as product_description, 	25704,00	 as list_price,	25704,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540NA-GQ005, Celeron N3350 1.1 4GB 500GB USB2.0/USB3.0 WiFi BT HDMI камера SD 2.1кг DOS черный-золотистый	 ' as product_description, 	15990,00	 as list_price,	15990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540NA-GQ005T, Celeron N3350 1.1 4GB 500GB USB2.0/USB3.0 WiFi BT HDMI камера SD 2.1кг W10 черный-золотистый	 ' as product_description, 	18921,00	 as list_price,	18921,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540NA-GQ008, Pentium N4200 1.1 4GB 500GB 2*USB2.0/USB3.0 WiFi BT HDMI камера SD 2кг DOS черный-золотистый	 ' as product_description, 	21563,00	 as list_price,	21563,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540NA-GQ008T, Pentium N4200 1.1 4GB 500GB USB2.0/USB3.0 WiFi BT HDMI/VGA камера SD 2кг W10 черный-золотистый	 ' as product_description, 	23205,00	 as list_price,	23205,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540NV-DM027T, Pentium N4200 1.1 4GB 1Тб 1920*1080 GT920MX 2GB USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 1.9кг W10 коричневый	 ' as product_description, 	26561,00	 as list_price,	26561,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540NV-DM037, Celeron N3450 1.1 4GB 500GB 1920*1080 GT920MX 2GB 2*USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2кг DOS коричневый	 ' as product_description, 	22205,00	 as list_price,	22205,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540NV-GQ004T, Pentium N4200 1.1 4GB 500GB GT920MX 2GB USB2.0/USB3.0 WiFi BT HDMI камера SD 1.9кг W10 коричневый	 ' as product_description, 	27346,00	 as list_price,	27346,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540NV-GQ072, Pentium N4200 1.1 4GB 500GB GT920MX 2GB DVD-RW 2*USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 1.9кг DOS коричневый	 ' as product_description, 	26132,00	 as list_price,	26132,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540SA-XX012D, Celeron N3050 1.6 2GB 500GB USB2.0/USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD 1.73кг DOS черный-золотистый	 ' as product_description, 	15280,00	 as list_price,	15280,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540UA-DM597, Core i3-6006U 2.0 4GB 256GB SSD USB3.0/USB2.0 WiFi BT HDMI камера SD 2.04кг DOS коричневый	 ' as product_description, 	33772,00	 as list_price,	33772,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540UA-DM597T, Core i3-6006U 2.0 4GB 256GB SSD 1920*1080 USB2.0/USB3.0 WiFi BT HDMI камера SD 1.75кг W10 черный-золотистый	 ' as product_description, 	36414,00	 as list_price,	36414,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540UB-DM048T, Core i3-6006U 2.0 4GB 500GB 1920*1080 MX110 2GB 2*USB2.0/USB3.0 WiFi BT HDMI камера SD 2.04кг W10 черный-золотистый	 ' as product_description, 	32612,00	 as list_price,	32612,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X540YA-XO047T, AMD E1-7010 1.5 2GB 500GB Radeon R2 USB2.0/USB3.0 LAN WiFi BT HDMI/VGA камера SD 2.1кг W10 коричневый	 ' as product_description, 	16208,00	 as list_price,	16208,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X541NA-GQ245T, Celeron N3350 1.1 4GB 500GB USB2.0/USB3.0 USB-C LAN WiFi BT HDMI камера SD 2.1кг W10 черный-золотистый	 ' as product_description, 	21063,00	 as list_price,	21063,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X541NA-GQ283T, Pentium N4200 1.1 4GB 500GB USB2.0/USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD 2кг W10 черный-золотистый	 ' as product_description, 	23990,00	 as list_price,	23990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X541NA-GQ378, Celeron N3350 1.1 4GB 500GB DVD-RW USB2.0/USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD 2кг DOS черный-золотистый	 ' as product_description, 	20706,00	 as list_price,	20706,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X541NA-GQ559, Celeron N3350 1.1 4GB 1TB DVD-RW USB2.0/USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD 2кг DOS черный-золотистый	 ' as product_description, 	20842,00	 as list_price,	20842,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X541NA-GQ579, Celeron N3450 1.1 4GB 256GB SSD DVD-RW USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.1кг DOS серый-коричневый	 ' as product_description, 	23817,00	 as list_price,	23817,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X541NC-GQ081T, Pentium N4200 1.1 4GB 500GB GT810M 2GB USB2.0/USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD 1.9кг W10 черный-золотистый	 ' as product_description, 	24847,00	 as list_price,	24847,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X541SA-XX327D, Pentium N3710 1.6 2GB 500GB USB2.0/USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD 1.82кг DOS черный-золотистый	 ' as product_description, 	18635,00	 as list_price,	18635,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X541UA-DM517T, Core i5-6198D 2.3 4GB 1Тб USB2.0/2*USB3.0 LAN WiFi BT HDMI/VGA камера SD 2.04кг W10 черный-золотистый	 ' as product_description, 	36735,00	 as list_price,	36735,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X541UA-GQ1247D, Core i3-6006U 2.0 4GB 500GB USB2.0/USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD 2кг DOS золотистый-черный	 ' as product_description, 	24419,00	 as list_price,	24419,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X541UJ-GQ438T, Core i5-7200U 2.5 4GB 500GB GT920M 2GB DVD-RW USB3.0/USB2.0 USB-C LAN WiFi BT HDMI/VGA камера SD 2.04кг W10 золотистый-черный	 ' as product_description, 	43197,00	 as list_price,	43197,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X541UV-GQ988, Core i3-7100U 2.4 4GB 500GB GT920MX 2GB USB2.0/USB3.0 USB-C LAN WiFi BT HDMI камера SD 2.04кг DOS черный-золотистый	 ' as product_description, 	32558,00	 as list_price,	32558,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X542UA-DM572, Pentium 4405U 2.1 8GB 1Тб 1920*1080 USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD DOS серый	 ' as product_description, 	24990,00	 as list_price,	24990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X542UA-GQ003, Core i3-7100U 2.4 4GB 500GB DVD-RW USB2.0/2*USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD 2кг DOS синий	 ' as product_description, 	32451,00	 as list_price,	32451,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X542UQ-DM274T, Core i3-7100U 2.4 6GB 500GB 1920*1080 GT940MX 2GB 2*USB3.0 USB-C LAN WiFi BT HDMI камера SD 2кг W10 серый	 ' as product_description, 	38056,00	 as list_price,	38056,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X556UQ-DM812D, Core i3-6100U 2.3 8GB 1Тб GT940MX 2GB USB2.0/USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD 2.2кг DOS белый	 ' as product_description, 	38991,00	 as list_price,	38991,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X556UQ-XO769T, Core i5-7200U 2.5 4GB 1Тб GT940MX 2GB DVD-RW USB2.0/USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD 2.25кг W10 белый	 ' as product_description, 	42840,00	 as list_price,	42840,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" ASUS X570UD-E4021T, Core i5-8250U 1.6 8GB 1Тб 1920*1080 IPS GTX1050 2GB USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 1.99кг W10 черный	 ' as product_description, 	58905,00	 as list_price,	58905,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Acer Aspire 3 A315-51-32P6 (NX.GZ4ER.001), Core i3-8130U 4GB 500GB 2*USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.1кг Linux синий	 ' as product_description, 	30559,00	 as list_price,	30559,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Acer E5-575G-396N, Core i3-6100U 2.3 4GB 500GB GT940MX 2GB 2*USB3.0 USB-C LAN WiFi BT HDMI камера SD 2кг W10 черный	 ' as product_description, 	32630,00	 as list_price,	32630,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Acer Extensa EX2519-P79W (NX.EFAER.025), Pentium N3710 1.6 4GB 500GB DVD-RW 2*USB2.0/USB3.0 LAN WiFi BT HDMI/VGA камера SD 2.2кг Linux черный	 ' as product_description, 	19992,00	 as list_price,	19992,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Acer Extensa EX2540-38MS (NX.EFHER.072), Core i3-6006U 4GB 128GB SSD 1920*1080 2*USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.4кг DOS черный	 ' as product_description, 	32487,00	 as list_price,	32487,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 3541-1387, AMD A6-6310 1.8 4GB 500GB Radeon R4 DVD-RW 2USB2.0/USB3.0 LAN WiFi BT HDMI камера SD/SDHC/SDXC 2.4кг W10 черный	 ' as product_description, 	22848,00	 as list_price,	22848,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 3552-0507, Celeron N3060 1.6 4GB 500GB DVD-RW 2USB2.0/USB3.0 WiFi BT HDMI камера SD 2.2кг Linux черный	 ' as product_description, 	18350,00	 as list_price,	18350,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 3552-0514, Celeron N3060 1.6 4GB 500GB DVD-RW 2*USB2.0/USB3.0 WiFi BT HDMI камера SD 2.2кг W10 черный	 ' as product_description, 	20135,00	 as list_price,	20135,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 3552-0569, Pentium N3710 1.6 4GB 500GB DVD-RW 2USB2.0/2USB3.0 WiFi BT HDMI камера SD/SDHC/SDXC 2.2кг Linux черный	 ' as product_description, 	19849,00	 as list_price,	19849,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 3552-5864, Celeron N3050 1.6 2GB 500GB 2USB2.0/USB3.0 WiFi BT HDMI камера SD 2.2кг Linux черный	 ' as product_description, 	16636,00	 as list_price,	16636,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 3558-5285, Core i5-5200U 2.2 4GB 500GB GT920M 2GB DVD-RW 2USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.2кг W10 черный	 ' as product_description, 	37485,00	 as list_price,	37485,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 3567-1069, Core i3-6006U 2.0 4GB 1Тб 1920*1080 R5 M430 2GB DVD-RW USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.2кг Linux черный	 ' as product_description, 	30984,00	 as list_price,	30984,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 3567-1137, Core i5-7200U 2.5 4GB 500GB 1920*1080 R5 M430 2GB DVD-RW USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.2кг Linux черный	 ' as product_description, 	37320,00	 as list_price,	37320,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 3567-1144, Core i5-7200U 2.5 4GB 500GB R5 M430 2GB DVD-RW 2USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.2кг W10 черный	 ' as product_description, 	40484,00	 as list_price,	40484,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 3567-1882, Core i5-7200U 2.5 6GB 1Тб 1920*1080 R5 M430 2GB DVD-RW USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.2кг Linux черный	 ' as product_description, 	36557,00	 as list_price,	36557,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 3567-7855, Core i3-6006U 2.0 4GB 500GB DVD-RW USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD/SDHC/SDXC 2.4кг Linux черный	 ' as product_description, 	25061,00	 as list_price,	25061,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 3567-7862, Core i3-6006U 2.0 4GB 1Тб DVD-RW USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.2кг W10 черный	 ' as product_description, 	30702,00	 as list_price,	30702,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 5558-8193, Core i3-5005U 2.0 4GB 1Тб GT920M 2GB DVD-RW 2USB2.0/USB3.0 LAN WiFi BT HDMI камера SD/SDHC/SDXC 2.2кг Linux черный	 ' as product_description, 	31559,00	 as list_price,	31559,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 5567-3195, Core i7-7500U 2.7 8GB 1Тб R7 M445 4GB 2*USB3.0 LAN WiFi BT HDMI камера SD 2.36кг W10 черный	 ' as product_description, 	56602,00	 as list_price,	56602,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 5567-7935, Core i3-6006U 2.0 4GB 1Тб R7 M440 2GB DVD-RW USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.4кг W10 белый-черный	 ' as product_description, 	36735,00	 as list_price,	36735,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Dell Inspiron 7567-9309, Core i5-7300HQ 2.5 8GB 1TB+8GB SSD GTX1050 4GB 3*USB3.0 LAN WiFi BT HDMI камера SD 2.6кг W10 черный	 ' as product_description, 	61047,00	 as list_price,	61047,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-ac001ur (N2K26EA), Celeron N3050 1.6 2GB 500GB 2USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.5кг DOS черный	 ' as product_description, 	17707,00	 as list_price,	17707,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-ac101ur (P0G02EA), Celeron N3050 1.6 2GB 500GB 2USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.2кг DOS черный	 ' as product_description, 	16065,00	 as list_price,	16065,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-af001ur (N2K35EA), AMD E1-6015 1.4 2GB 500GB Radeon R2 2USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.19кг DOS черный	 ' as product_description, 	14394,00	 as list_price,	14394,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-af123ur (P0U35EA), AMD E1-6015 1.4 2GB 500GB Radeon R2 2USB2.0/USB3.0 LAN WiFi HDMI камера SD 2.05кг DOS черный	 ' as product_description, 	14324,00	 as list_price,	14324,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-ay013ur (W6Y53EA), Celeron N3060 1.6 2GB 500GB 2USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2кг DOS черный	 ' as product_description, 	16136,00	 as list_price,	16136,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-ay063ur (X5Y60EA), Core i3-5005U 2.0 4GB 500GB 1920*1080 R5 M430 2GB 2USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.2кг W10 черный	 ' as product_description, 	27489,00	 as list_price,	27489,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-ay075ur (X7H95EA), Core i7-6500U 2.5 4GB 500GB 1920*1080 R7 M440 2GB 2*USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.04кг W10 черный	 ' as product_description, 	45339,00	 as list_price,	45339,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-ay500ur (Y5K68EA), Pentium N3710 1.6 4GB 500GB 1920*1080 R5 M430 2GB DVD-RW 2*USB2.0/USB3.0 LAN WFi BT HDMI камера SD 2.04кг W10 серый	 ' as product_description, 	27489,00	 as list_price,	27489,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-ay556ur (Z9C23EA), Core i3-6006U 2.0 4GB 500GB 2*USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.1кг DOS черный	 ' as product_description, 	25847,00	 as list_price,	25847,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-ba523ur (Y6J06EA), AMD A8-7410 2.2 6GB 500GB 1920*1080 Radeon R5 M430 2GB DVD-RW 2USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.04кг W10 черный	 ' as product_description, 	31559,00	 as list_price,	31559,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs010ur (1ZJ76EA), Pentium N3710 1.6 4GB 500GB AMD 520 2GB USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 1.9кг DOS черный	 ' as product_description, 	24365,00	 as list_price,	24365,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs012ur (1ZJ78EA), Core i3-6006U 2.0 4GB 500GB USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.1кг DOS черный	 ' as product_description, 	28340,00	 as list_price,	28340,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs041ur (1VH41EA), Pentium N3710 1.6 4GB 500GB USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.1кг W10 серый	 ' as product_description, 	24990,00	 as list_price,	24990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs042ur (1VH42EA), Pentium N3710 1.6 4GB 500GB USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 1.91кг W10 синий	 ' as product_description, 	25490,00	 as list_price,	25490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs046ur (1VH45EA), Pentium N3710 1.6 4GB 500GB AMD 520 2GB 2*USB2.0/USB3.0 LAN WFi BT HDMI камера SD 2.04кг W10 черный-серебристый	 ' as product_description, 	26989,00	 as list_price,	26989,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs047ur (1VH46EA), Pentium N3710 1.6 4GB 500GB AMD 520 2GB 2*USB2.0/USB3.0 LAN WFi BT HDMI камера SD 2.1кг W10 золотистый-черный	 ' as product_description, 	29274,00	 as list_price,	29274,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs048ur (1VH47EA), Pentium N3710 1.6 4GB 500GB AMD 520 2GB 2*USB2.0/USB3.0 LAN WFi BT HDMI камера SD 2.1кг W10 белый	 ' as product_description, 	27889,00	 as list_price,	27889,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs050ur (1VH49EA), Pentium N3710 1.6 4GB 500GB AMD 520 2GB 2*USB2.0/USB3.0 LAN WFi BT HDMI камера SD 2.1кг W10 синий	 ' as product_description, 	26918,00	 as list_price,	26918,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs053ur (1VH51EA), Core i3-6006U 2.0 4GB 500GB USB2.0/2*USB3.1 LAN WiFi BT HDMI камера SD 2.1кг W10 черный	 ' as product_description, 	28489,00	 as list_price,	28489,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs055ur (1VH53EA), Core i3-6006U 2.0 4GB 500GB USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 1.92кг W10 золотистый-черный	 ' as product_description, 	28560,00	 as list_price,	28560,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs079ur (1VH74EA), Core i3-6006U 2.0 4GB 1Тб 1920*1080 AMD 520 2GB DVD-RW 2*USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.1кг DOS черный	 ' as product_description, 	31273,00	 as list_price,	31273,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs100ur (2VZ79EA), Core i5-8250U 1.6 8GB 1Тб 1920*1080 AMD 520 2GB 2*USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.04кг DOS синий-черный	 ' as product_description, 	47481,00	 as list_price,	47481,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs151ur (3XY37EA), Core i3-5005U 2.0 4GB 500GB 2*USB3.0/USB2.0 LAN WiFi BT HDMI камера SD 1.85кг DOS черный	 ' as product_description, 	26989,00	 as list_price,	26989,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs158ur (3XY59EA), Core i3-5005U 2.0 4GB 500GB DVD-RW 2*USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.1кг DOS черный	 ' as product_description, 	27846,00	 as list_price,	27846,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs164ur (4UK90EA), Core i3-5005U 2.0 4GB 1Тб DVD-RW USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 1.92кг W10 черный	 ' as product_description, 	27490,00	 as list_price,	27490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs166ur (4UK92EA), Core i3-5005U 2.0 4GB 1Тб USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.1кг DOS черный	 ' as product_description, 	28703,00	 as list_price,	28703,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs509ur (2FQ64EA), Pentium N3710 1.6 4GB 500GB 1920*1080 USB2.0/2*USB3.0 LAN WFi BT HDMI камера SD 2.04кг W10 черный	 ' as product_description, 	23419,00	 as list_price,	23419,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bs650ur (3LG77EA), Celeron N3060 1.6 4GB 128GB SSD USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.23кг W10 черный	 ' as product_description, 	22348,00	 as list_price,	22348,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bw007ur (1ZD18EA), AMD E2-9000e 1.5 4GB 128GB SSD Radeon R2 USB2.0/2*USB3.1 LAN WiFi BT HDMI камера SD 1.91кг W10 черный	 ' as product_description, 	19421,00	 as list_price,	19421,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bw013ur (1ZK02EA), AMD A4-9120 2.2 4GB 500GB Radeon R2 USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.1кг DOS черный	 ' as product_description, 	18064,00	 as list_price,	18064,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bw042ur (2CQ04EA), AMD A6-9220 2.5 4GB 500GB AMD 520 2GB USB2.0/2*USB3.1 LAN WiFi BT HDMI камера SD 2.1кг DOS черный	 ' as product_description, 	22791,00	 as list_price,	22791,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bw058ur (2CQ06EA), AMD A6-9220 2.5 4GB 500GB USB2.0/2*USB3.1 LAN WiFi BT HDMI камера SD 2.1кг DOS черный	 ' as product_description, 	19778,00	 as list_price,	19778,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bw066ur (2CN97EA), AMD A12-9720P 2.7 6GB 1Тб 1920*1080 AMD 530 4GB USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.28кг W10 серебристый-черный	 ' as product_description, 	38199,00	 as list_price,	38199,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bw067ur (2BT83EA), AMD A10-9620P 2.5 8GB 1Тб AMD 530 2GB USB2.0/2*USB3.1 LAN WiFi BT HDMI камера SD 2.28кг W10 черный	 ' as product_description, 	37842,00	 as list_price,	37842,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bw090ur (2CJ98EA), AMD A6-9220 2.5 4GB 500GB AMD 520 2GB DVD-RW USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.04кг W10 черный	 ' as product_description, 	27560,00	 as list_price,	27560,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bw530ur (2FQ67EA), AMD A6-9220 2.5 4GB 500GB Radeon R4 USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.04кг W10 черный	 ' as product_description, 	24140,00	 as list_price,	24140,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bw536ur (2GF36EA), AMD A6-9220 2.5 4GB 500GB AMD 520 2GB DVD-RW USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.04кг W10 синий	 ' as product_description, 	27846,00	 as list_price,	27846,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bw594ur (2PW83EA), AMD E2-9000e 1.5 4GB 500GB 1920*1080 Radeon R2 USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 1.91кг W10 серый	 ' as product_description, 	19921,00	 as list_price,	19921,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-bw613ur (2QH60EA), AMD A6-9220 2.5 4GB 128GB SSD 1920*1080 Radeon R4 USB2.0/2*USB3.1 LAN WiFi BT HDMI камера SD 2.1кг DOS черный	 ' as product_description, 	22848,00	 as list_price,	22848,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-cb013ur (2CM41EA), Core i5-7300HQ 2.5 8GB 1Тб 1920*1080 IPS GTX1050 2GB 3*USB3.0 USB-C LAN WiFi BT HDMI камера SD 2.3кг DOS черный	 ' as product_description, 	58548,00	 as list_price,	58548,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-ck013ur (2PT03EA), Core i5-8250U 1.6 4GB 500GB 1920*1080 IPS GT940MX 2*USB3.1 USB-C LAN WiFi BT HDMI камера SD 1.86кг W10 золотистый	 ' as product_description, 	48195,00	 as list_price,	48195,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" HP 15-ck017ur (2VZ81EA), Core i5-8250U 1.6 4GB 500GB 1920*1080 IPS GT940MX 2*USB3.1 USB-C LAN WiFi BT HDMI камера SD 1.86кг W10 серый-серебристый	 ' as product_description, 	49980,00	 as list_price,	49980,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo 320-15IKB (80XL02WXRK), Core i5-7200U 2.5 4GB 500GB GT940MX 2GB 2*USB3.0/USB3.1 LAN WiFi HDMI камера SD 2.1кг DOS серый	 ' as product_description, 	37110,00	 as list_price,	37110,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo IdeaPad 320-15ISK (80XH01NKRK), Core i3-6006U 2.0 4GB 1Тб USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.02кг DOS черный	 ' as product_description, 	28489,00	 as list_price,	28489,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo IdeaPad V110-15ISK (80TL0146RK), Core i3-6006U 2.0 4GB 500GB DVD-RW USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.02кг DOS черный	 ' as product_description, 	25704,00	 as list_price,	25704,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo IdeaPad V310-15ISK (80SY02S6RK), Core i3-6006U 2.0 4GB 500GB 1920*1080 2USB2.0/USB3.0 LAN WiFi BT HDMI/VGA камера SD 1.89кг DOS черный	 ' as product_description, 	27346,00	 as list_price,	27346,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 100-15IBY (80MJ009VRK), Celeron N2840 2.16 2GB 500GB USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.3кг DOS черный	 ' as product_description, 	15280,00	 as list_price,	15280,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 110-15ACL (80TJ0041RK), AMD A6-7310 2.0 4GB 1Тб Radeon R4 USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 1.92кг W10 черный	 ' as product_description, 	24276,00	 as list_price,	24276,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 110-15ACL (80TJ00D3RK), AMD E1-7010 1.5 4GB 500GB Radeon R2 DVD-RW USB2.0/USB3.0 LAN WiFi HDMI камера SD 2.11кг W10 черный	 ' as product_description, 	21063,00	 as list_price,	21063,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 110-15IBR (80T7003JRK), Pentium N3710 1.6 2GB 500GB DVD-RW USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.03кг DOS черный	 ' as product_description, 	18743,00	 as list_price,	18743,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 110-15IBR (80T700C0RK), Celeron N3060 1.6 2GB 500GB USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 1.9кг W10 черный	 ' as product_description, 	16779,00	 as list_price,	16779,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15AST (80XV0022RK), AMD A6-9220 2.5 4GB 500GB AMD 530 2GB USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 1.92кг W10 серый	 ' as product_description, 	25704,00	 as list_price,	25704,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15AST (80XV0027RK), AMD A9-9420 3.0 4GB 500GB 1920*1080 AMD 530 2GB USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 1.92кг W10 черный	 ' as product_description, 	28060,00	 as list_price,	28060,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15AST (80XV00J6RK), AMD A6-9220 2.5 4GB 1Тб AMD 520 2GB USB2.0/2USB3.0 LAN WiFi HDMI камера SD 2кг DOS черный	 ' as product_description, 	25847,00	 as list_price,	25847,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15AST (80XV00JXRK), AMD E2-9000 1.8 4GB 500GB Radeon R2 USB2.0/2USB3.0 LAN WiFi HDMI камера SD 2.4кг DOS серый	 ' as product_description, 	16779,00	 as list_price,	16779,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15AST (80XV00WWRU), AMD E2-9000 1.8 4GB 500GB Radeon R2 USB2.0/2USB3.0 LAN WiFi HDMI камера SD 2.4кг DOS серый	 ' as product_description, 	17493,00	 as list_price,	17493,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IAP (80XR0020RK), Pentium N4200 1.1 4GB 500GB 1920*1080 2*USB2.0/USB3.0 LAN WiFi BT HDMI/VGA камера SD 2.2кг W10 серый	 ' as product_description, 	26204,00	 as list_price,	26204,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IAP (80XR002LRK), Pentium N4200 1.1 4GB 500GB 1920*1080 AMD 520 2GB USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.3кг W10 серый	 ' as product_description, 	26418,00	 as list_price,	26418,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IAP (80XR00L2RK), Pentium N4200 1.1 8GB 1Тб AMD 530 2GB USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.3кг W10 серый	 ' as product_description, 	27703,00	 as list_price,	27703,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IAP (80XR00WNRK), Pentium N4200 1.1 4GB 1Тб 1920*1080 AMD 530 2GB USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.3кг W10 черный	 ' as product_description, 	27846,00	 as list_price,	27846,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IAP (80XR00X0RK), Pentium N4200 1.1 4GB 500GB USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.03кг DOS черный	 ' as product_description, 	20635,00	 as list_price,	20635,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IAP (80XR00XVRK), Celeron N3350 1.1 4GB 500GB USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 1.9кг DOS черный	 ' as product_description, 	19814,00	 as list_price,	19814,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IAP (80XR013QRK), Celeron N3350 1.1 4GB 500GB 1920*1080 USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 1.9кг DOS черный	 ' as product_description, 	17993,00	 as list_price,	17993,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IAP (80XR0166RK), Pentium N4200 1.1 4GB 1Тб 1920*1080 AMD 530 2GB USB2.0/2USB3.0 LAN WiFi BT HDMI камера SD 2.3кг DOS черный	 ' as product_description, 	24276,00	 as list_price,	24276,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IAP (80XR018RRU), Pentium N4200 1.1 4GB 500GB 1920*1080 USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 1.99кг DOS серебристый	 ' as product_description, 	21563,00	 as list_price,	21563,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IKB (80XL01GPRK), Core i5-7200U 2.5 4GB 1Тб 1920*1080 GT940MX 2GB 2*USB3.0/USB3.1 LAN WiFi HDMI камера SD 2.1кг W10 серый	 ' as product_description, 	42269,00	 as list_price,	42269,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IKB (80XL024HRK), Core i5-7200U 2.5 4GB 1Тб 1920*1080 GT940MX 2GB 2*USB3.0/USB3.1 LAN WiFi HDMI камера SD 2.1кг W10 серый	 ' as product_description, 	42733,00	 as list_price,	42733,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IKB (80XL02WYRK), Core i5-7200U 2.5 4GB 500GB 1920*1080 GT940MX 2GB USB2.0/2*USB3.0 LAN WiFi HDMI камера SD 2.1кг DOS серый	 ' as product_description, 	39056,00	 as list_price,	39056,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IKB (80YE009ERK), Core i5-7200U 2.5 4GB 500GB AMD 520 2GB 2*USB3.0/USB3.1 LAN WiFi HDMI камера SD 2.1кг W10 черный	 ' as product_description, 	36057,00	 as list_price,	36057,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IKB (80YE009WRK), Core i5-7200U 2.5 4GB 500GB AMD 520 2GB 2*USB3.0 USB-C LAN WiFi HDMI камера SD 2.1кг DOS серый	 ' as product_description, 	33558,00	 as list_price,	33558,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IKBN (80XL01GFRK), Core i3-7100U 2.4 4GB 1Тб 1920*1080 IPS GT940MX 2GB 2*USB3.0 USB-C LAN WiFi BT HDMI камера SD 2.1кг W10 серый	 ' as product_description, 	35129,00	 as list_price,	35129,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IKBN (80XL03U1RU), Core i3-7130U 2.7 4GB 1Тб 1920*1080 GT940MX 2GB 2*USB3.0 USB-C LAN WiFi BT HDMI камера SD 2.1кг W10 серый	 ' as product_description, 	38413,00	 as list_price,	38413,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IKBR (81DE005URU), Core i3-8130U 2.2 8GB 1Тб MX150 2GB 2*USB3.0 USB-C LAN WiFi BT HDMI камера SD 2.1кг W10 черный	 ' as product_description, 	44125,00	 as list_price,	44125,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IKBRA (81BT001KRK), Core i5-8250U 1.6 4GB 1ТБ AMD 530 2GB USB2.0/USB3.0 LAN WiFi HDMI камера SD 2.1кг W10 черный	 ' as product_description, 	42733,00	 as list_price,	42733,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15IKBRN (81BG00L0RU), Core i7-8550U 1.8 8GB 1TB 1920*1080 IPS MX150 4GB 2*USB3.0 USB-C LAN WiFi HDMI камера SD 2.3кг DOS черный	 ' as product_description, 	53015,00	 as list_price,	53015,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15ISK (80XH00EHRK), Core i3-6006U 2.0 4GB 500GB GT920MX 2GB USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 1.95кг W10 черный	 ' as product_description, 	32990,00	 as list_price,	32990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15ISK (80XH01EHRK), Core i3-6006U 2.0 4GB 500GB GT920MX 2GB 2*USB3.0 USB-C LAN WiFi BT HDMI камера SD 1.85кг DOS черный	 ' as product_description, 	31591,00	 as list_price,	31591,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15ISK (80XH01YPRU), Core i3-6006U 2.0 4GB 1Тб USB2.0/2*USB3.0 LAN WiFi BT HDMI/VGA камера SD 2.02кг W10 черный	 ' as product_description, 	28917,00	 as list_price,	28917,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 320-15ISK (80XH022YRU), Core i3-6006U 2.0 6GB 1Тб 1920*1080 GT920MX 2GB 2*USB3.0 USB-C LAN WiFi BT HDMI камера SD 2.2кг DOS черный	 ' as product_description, 	29417,00	 as list_price,	29417,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 330-15AST (81D6001QRU), AMD A6-9225 2.6 4GB 500GB 1920*1080 USB2.0/2USB3.0 LAN WiFi HDMI камера SD 2кг DOS черный	 ' as product_description, 	20670,00	 as list_price,	20670,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 330-15AST (81D600FRRU), AMD E2-9000 1.8 4GB 128GB Radeon R2 USB2.0/USB3.0 LAN WiFi HDMI камера SD 2.11кг W10 черный	 ' as product_description, 	23633,00	 as list_price,	23633,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 330-15IGM (81D10032RU), Pentium N5000 1.1 4GB 500GB 1920*1080 AMD 530 2GB USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.3кг W10 черный	 ' as product_description, 	26775,00	 as list_price,	26775,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 520-15IKB (80YL00H5RK), Core i5-7200U 2.5 4GB 1Тб 1920*1080 IPS GT940MX 2GB 2*USB3.0/USB3.1 LAN WiFi HDMI камера SD 2.1кг W10 серый	 ' as product_description, 	46053,00	 as list_price,	46053,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 520-15IKBR (81BF0058RK), Core i5-8250U 1.6 6GB 1ТБ 1920*1080 IPS GF MX150 2GB 2*USB3.0 USB-C LAN WiFi HDMI камера SD 2.1кг W10 серый	 ' as product_description, 	50230,00	 as list_price,	50230,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 520-15IKBR (81BF005ARK), Core i5-8250U 1.6 4GB 1Тб 1920*1080 IPS MX150 2GB USB2.0/2*USB3.0 LAN WiFi HDMI камера SD 2.1кг DOS коричневый	 ' as product_description, 	43197,00	 as list_price,	43197,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad 700-15ISK (80RU00JARK), Core i7-6700HQ 2.6 8GB 1TB 1920*1080 IPS GTX950M 4GB 2USB2.0/USB3.0 LAN WiFi HDMI/VGA камера SD 2.3кг W10 черный	 ' as product_description, 	60726,00	 as list_price,	60726,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad V110-15AST (80TD003XRK), AMD A6-9210 2.4 4GB 500GB DVD-RW USB2.0/2USB3.0 LAN WiFi HDMI камера SD 2кг DOS черный	 ' as product_description, 	19278,00	 as list_price,	19278,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad V110-15IAP (80TG001PRK), Pentium N4200 1.1 4GB 1Тб USB2.0/USB3.0 LAN WiFi BT HDMI камера SD/SDHC/SDXC 2кг W10 черный	 ' as product_description, 	24347,00	 as list_price,	24347,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad V110-15IAP (80TG00ATRK), Pentium N4200 1.1 4GB 1Тб USB2.0/USB3.0 LAN WiFi BT HDMI камера SD/SDHC/SDXC 1.9кг DOS черный	 ' as product_description, 	21420,00	 as list_price,	21420,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad V110-15IAP (80TG00BDRK), Pentium N4200 1.1 4GB 500GB USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.03кг DOS черный	 ' as product_description, 	21777,00	 as list_price,	21777,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad V110-15IAP (80TG00GARK), Celeron N3350 1.1 4GB 500GB DVD-RW USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 1.9кг DOS черный	 ' as product_description, 	18368,00	 as list_price,	18368,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad V110-15IKB (80TH000VRK), Core i5-7200U 2.5 4GB 500GB DVD-RW 2*USB3.0 LAN WiFi HDMI камера SD 2.1кг DOS черный	 ' as product_description, 	32612,00	 as list_price,	32612,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 15" Lenovo Ideapad V310-15ISK (80SY02RMRK), Core i3-6006U 2.0 4GB 500GB DVD-RW USB2.0/2*USB3.0 LAN WiFi BT HDMI/VGA камера SD 2.02кг W10 черный	 ' as product_description, 	31773,00	 as list_price,	31773,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" ASUS K751NV-TY028T, Pentium N4200 1.1 4GB 500GB 1600*900 GT920MX 2GB DVD-RW 2*USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.8кг W10 черный	 ' as product_description, 	28917,00	 as list_price,	28917,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" ASUS X705UV-BX226T, Core i3-6006U 2.0 8GB 1Тб 1600*900 GT920MX 2GB USB2.0/USB3.0 USB-C LAN WiFi BT HDMI камера SD 2.8кг W10 серый	 ' as product_description, 	47124,00	 as list_price,	47124,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" ASUS X751NA-TY001T, Pentium N4200 4GB 500GB 1600*900 DVD-RW 2*USB2.0/USB3.0 LAN WiFi BT HDMI/VGA камера SD W10 черный	 ' as product_description, 	28863,00	 as list_price,	28863,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" ASUS X751NV-TY001T, Pentium N4200 1.1 4GB 1Тб 1600*900 GT920M 2GB DVD-RW USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD/SDHC/SDXC 2.8кг W10 черный	 ' as product_description, 	33737,00	 as list_price,	33737,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" ASUS X751SA-TY165T, Pentium N3710 1.6 4GB 500GB 1600*900 DVD-RW 2*USB2.0/USB3.0 LAN WiFi BT HDMI/VGA камера SD 2.5кг W10 черный	 ' as product_description, 	29238,00	 as list_price,	29238,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" ASUS X751SJ-TY017T, Pentium N3700 1.6 4GB 500GB 1600*900 GT920M 1GB DVD-RW 2USB2.0/USB3.0 LAN WiFi BT HDMI камера SD/SDHC/SDXC 2.8кг W10 черный	 ' as product_description, 	32130,00	 as list_price,	32130,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" ASUS X756UV-TY077T, Core i3-6100U 2.3 4GB 500GB 1600*900 GT920MX 2GB DVD-RW 2*USB2.0/USB3.0 USB-C LAN WiFi BT HDMI/VGA камера SD/SDHC/SDXC 2.8кг W10 коричневый	 ' as product_description, 	38056,00	 as list_price,	38056,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" Dell Inspiron 5770-4921, Pentium 4415U 2.3 4GB 1Тб 1600*900 DVD-RW USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.8кг W10 черный	 ' as product_description, 	28167,00	 as list_price,	28167,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" HP 17-ak020ur (2CP33EA), AMD E2-9000e 1.5 4GB 128GB SSD 1600*900 Radeon R2 DVD-RW USB2.0/2*USB3.1 LAN WiFi BT HDMI камера SD 2.5кг W10 черный	 ' as product_description, 	27775,00	 as list_price,	27775,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" HP 17-bs007ur (1ZJ25EA), Celeron N3060 1.6 4GB 500GB DVD-RW USB2.0/2*USB3.1 LAN WiFi BT HDMI камера SD 2.65кг W10 черный	 ' as product_description, 	25597,00	 as list_price,	25597,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" HP 17-bs016ur (1ZJ34EA), Core i7-7500U 2.7 8GB 1TB 1600*900 AMD 520 2GB DVD-RW 2*USB3.0/USB2.0 LAN WiFi BT HDMI камера SD 2.5кг W10 серебристый-черный	 ' as product_description, 	57977,00	 as list_price,	57977,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" HP 17-bs028ur (2CS57EA), Pentium N3710 1.6 4GB 1Тб 1600*900 AMD 520 2GB DVD-RW USB2.0/2*USB3.0 LAN WiFi BT HDMI камера SD 2.6кг DOS серебристый-черный	 ' as product_description, 	29345,00	 as list_price,	29345,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" HP 17-bs101ur (2PN23EA), Core i5-8250U 1.6 6GB 1Тб 1920*1080 IPS AMD 530 2GB DVD-RW USB2.0/2USB3.0 LAN WiFi BT HDMI камера SD 2.7кг W10 серебристый-черный	 ' as product_description, 	53550,00	 as list_price,	53550,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" HP 17-by0005ur (4KG19EA), Pentium N5000 1.1 4GB 500GB 1600*900 AMD 520 2GB DVD-RW 2*USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.6кг W10 черный	 ' as product_description, 	35129,00	 as list_price,	35129,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" HP 17-x021ur (Y5L04EA), Pentium N3710 1.6 4GB 500GB 1600*900 Radeon R5 M430 2GB DVD-RW 2*USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.6кг W10 черный	 ' as product_description, 	33069,00	 as list_price,	33069,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" Lenovo Ideapad 110-17ACL (80UM0055RK), AMD E1-7010 1.5 4GB 500GB 1600*900 Radeon R2 2USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.8кг W10 черный	 ' as product_description, 	21277,00	 as list_price,	21277,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" Lenovo Ideapad 320-17ABR (80YN0001RK), AMD A10-9620P 2.5 8GB 1Тб 1600*900 AMD 520 2GB DVD-RW USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.8кг W10 черный	 ' as product_description, 	39698,00	 as list_price,	39698,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" Lenovo Ideapad 320-17AST (80XW0001RK), AMD A4-9120 2.2 4GB 1Тб 1600*900 Radeon R3 DVD-RW 2USB2.0/USB3.0 LAN WiFi BT HDMI камера SD 2.8кг W10 серый	 ' as product_description, 	28152,00	 as list_price,	28152,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" Lenovo Ideapad 320-17IKB (80XM00J9RU), Core i3-7130U 2.7 4GB 500GB 1600*900 GT940MX 2GB 2*USB2.0/USB3.0 LAN WiFi BT HDMI/VGA камера SD 2.7кг W10 серый	 ' as product_description, 	40520,00	 as list_price,	40520,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук 17" Lenovo Ideapad 330-17IKB (81DM000SRU), Core i5-8250U 1.6 4GB 1ТБ 1920*1280 IPS MX150 4GB USB3.0/USB3.1 LAN WiFi HDMI камера SD W10 черный	 ' as product_description, 	51765,00	 as list_price,	51765,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Ноутбук сенсорный 11" ASUS TP201SA-FV0009T, Celeron N3060 1.6 2GB 500GB USB2.0/USB3.0 WiFi BT HDMI камера SD/SDHC/SDXC 1.4 кг W10 черный-коричневый	 ' as product_description, 	17493,00	 as list_price,	17493,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 2 (ZE551ML-6A147RU), 4*2.33ГГц, 32GB, 5.5" 1920*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 13/5Мпикс, Android 5, 77.2*152.5*10.9мм 170г, черный	 ' as product_description, 	11850,00	 as list_price,	11850,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 2 (ZE551ML-6C178RU), 4*1.8ГГц, 16GB, 5.5" 1920*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 13/5Мпикс, Android 5, 77.2*152.5*10.9мм 170г, красный	 ' as product_description, 	9450,00	 as list_price,	9450,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 2 (ZE551ML-6G179RU), 4*1.8ГГц, 16GB, 5.5" 1920*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi,  радио, 2 камеры 13/5Мпикс, Android 5, 77.2*152.5*10.9мм 170г, золотистый	 ' as product_description, 	9990,00	 as list_price,	9990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 2 (ZE551ML-6J151RU), 4*2.33ГГц, 32GB, 5.5" 1920*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 13/5Мпикс, Android 5, 77.2*152.5*10.9мм 170г, серебристый	 ' as product_description, 	11490,00	 as list_price,	11490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 2 (ZE551ML-6J177RU), 4*1.8ГГц, 16GB, 5.5" 1920*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi,  радио, 2 камеры 13/5Мпикс, Android 5, 77.2*152.5*10.9мм 170г, серебристый	 ' as product_description, 	8545,00	 as list_price,	8545,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 2 Laser (ZE500KL-1A119RU), 4*1.2ГГц, 16GB, 5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 13/5Мпикс, Android 5, 71.5*143.7*10.5мм 140г, черный	 ' as product_description, 	10490,00	 as list_price,	10490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 2 Laser (ZE500KL-1B120RU), 4*1.2ГГц, 16GB, 5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 13/5Мпикс, Android 5, 71.5*143.7*10.5мм 140г, белый	 ' as product_description, 	11166,00	 as list_price,	11166,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 2 Laser (ZE550KL-1A047RU), 4*1.2ГГц, 16GB, 5.5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 13/5Мпикс, Android 5, 77.2*152.5*10.9мм, 170г, черный	 ' as product_description, 	10700,00	 as list_price,	10700,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 2 Laser (ZE550KL-1B048RU), 4*1.2ГГц, 16GB, 5.5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 13/5Мпикс, Android 5, 77.2*152.5*10.9мм, 170г, белый	 ' as product_description, 	11897,00	 as list_price,	11897,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 2 Laser (ZE601KL-6G038RU), 8*1.7ГГц, 32GB, 6" 1920*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 13/5Мпикс, Android 5, 84*164.5*10.5мм 190г, золотистый	 ' as product_description, 	13500,00	 as list_price,	13500,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 3 (ZE520KL-1A042RU), 8*2ГГц, 32GB, 5.2" 1920*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 16/8Мпикс, Android 6, 73.98*146.87*7.69мм 155г, черный	 ' as product_description, 	14400,00	 as list_price,	14400,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 3 (ZE552KL-1A053RU), 8*2ГГц, 64GB, 5.5" 1920*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 16/8Мпикс, Android 6, 77.3*152.6*7.69мм 155г, черный	 ' as product_description, 	19990,00	 as list_price,	19990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 3 Max (ZC520TL-4G021RU), 4*1.2ГГц, 16GB, 5.2" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 13/5Мпикс, Android 6, 73.7*149.5*8.6мм 148г, золотистый	 ' as product_description, 	9990,00	 as list_price,	9990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 3 Max (ZC520TL-4H022RU), 4*1.2ГГц, 16GB, 5.2" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 13/5Мпикс, Android 6, 73.7*149.5*8.6мм 148г, серый	 ' as product_description, 	9990,00	 as list_price,	9990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 4 (ZE554KL-1A085RU), 8*2.2, 64GB, 5.5" 1920*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, NFC, 3 камеры 12+8/8Мпикс, Android 7, 75.2*155.4*7.5мм, 165г, черный	 ' as product_description, 	21990,00	 as list_price,	21990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 4 Max (ZC520KL-4G033RU), 4*1.4ГГц, 16GB, 5.2" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 3 камеры 13+5/8Мпикс, Android 7, 73.3*150.5*8.73мм 156г, золотистый	 ' as product_description, 	9990,00	 as list_price,	9990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 4 Max (ZC554KL-4A001RU), 4*1.4ГГц, 16GB, 5.5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 3 камеры 16+5/8Мпикс, Android 7, 76.9*154*8.9мм 181г, черный	 ' as product_description, 	12490,00	 as list_price,	12490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 4 Max (ZC554KL-4G002RU), 4*1.4ГГц, 16GB, 5.5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 3 камеры 16+5/8Мпикс, Android 7, 76.9*154*8.9мм 181г, золотистый	 ' as product_description, 	11990,00	 as list_price,	11990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone 5 (A502CG-2B066RU), 2*1.2ГГц, 8GB, 5" 960*540, SD-micro/SDHC-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 8/0.3Мпикс, Android 4.4, 72.8*148.2*10.8мм 160г, белый	 ' as product_description, 	6200,00	 as list_price,	6200,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone Go (ZB452KG-1A052RU), 4*1.2ГГц, 8GB, 4.5" 854*480, SDHC-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 5/0.3Мпикс, Android 5.1, 67*136.5*11.2мм 125г, черный	 ' as product_description, 	4990,00	 as list_price,	4990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone Go (ZB500KL-1A049RU), 4*1ГГц, 16GB, 5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 13/5Мпикс, Android 6, 70.85*143.7*11.25мм 150г, черный	 ' as product_description, 	7990,00	 as list_price,	7990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone Live (ZB501KL-4A027A), 4*1.2ГГц, 32GB, 5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 6, 72*141*8мм, 120г, черный	 ' as product_description, 	8490,00	 as list_price,	8490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone Live (ZB501KL-4G005A), 4*1.2ГГц, 32GB, 5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 6, 72*141*8мм, 120г, золотистый	 ' as product_description, 	8990,00	 as list_price,	8990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone Live (ZB501KL-4I005A), 4*1.2ГГц, 32GB, 5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 6, 72*141*8мм, 120г, розовый	 ' as product_description, 	8790,00	 as list_price,	8790,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone Live (ZB553KL-5A081RU), 4*1.4ГГц, 16GB, 5.5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/13Мпикс, Android 7, 75.9*155.6*7.85мм, 144г, черный	 ' as product_description, 	8990,00	 as list_price,	8990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone Live (ZB553KL-5G082RU), 4*1.4ГГц, 16GB, 5.5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/13Мпикс, Android 7, 75.9*155.6*7.85мм, 144г, золотистый	 ' as product_description, 	8990,00	 as list_price,	8990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone Live L1 (ZA550KL-4A009RU), 4*1.4ГГц, 16GB, 5.5" 1440*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 8, 71.7*147.2*8.1мм, 140г, черный	 ' as product_description, 	7990,00	 as list_price,	7990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS ZenFone Max (ZC550KL-1B021RU), 4*1.2ГГц, 16GB, 5.5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 13/5Мпикс, Android 5, 77.5*156*10.5мм 220г, белый	 ' as product_description, 	13490,00	 as list_price,	13490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS Zenfone 5 Lite (ZC600KL-5A023RU), 8*1.5ГГц, 64GB, 6" 2160*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, NFC, радио, 4 камеры 20+8/16+8Мпикс, Android 7.1, 76*160*7.8мм 168г, черный	 ' as product_description, 	18990,00	 as list_price,	18990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS Zenfone 5 Lite (ZC600KL-5B025RU), 8*1.5ГГц, 64GB, 6" 2160*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, NFC, радио, 4 камеры 20+8/16+8Мпикс, Android 7.1, 76*160*7.8мм 168г, белый	 ' as product_description, 	18990,00	 as list_price,	18990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS Zenfone Max M2 (ZB633KL-4A005RU), 8*1.8ГГц, 32GB, 6.3" 2220*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 3 камеры 13+2/8Мпикс, Android 8.1, 76*158*7.7мм 160г, черный	 ' as product_description, 	12990,00	 as list_price,	12990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS Zenfone Max PRO M2 (ZB631KL-4D005RU), 8*1.95ГГц, 64GB, 6.3" 2220*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, NFC, радио, 3 камеры 12+5/13Мпикс, Android 8.1, 75.5*158*8.5мм, 170г, синий	 ' as product_description, 	17990,00	 as list_price,	17990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS Zenfone Max Plus M1 (ZB570TL-4A008RU), 8*1.5ГГц, 32GB, 5.7" 2160*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 3 камеры 16+8/8Мпикс, Android 7, 73*153*8.8мм 160г, черный	 ' as product_description, 	12990,00	 as list_price,	12990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS Zenfone Max Pro M1 (ZB602KL-4A005RU), 8*1.5ГГц, 32GB, 6" 2160*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, NFC, радио, 3 камеры 13+5/8Мпикс, Android 8, 76*159*8.45мм 180г, черный	 ' as product_description, 	13990,00	 as list_price,	13990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim ASUS Zenfone Max Pro M1 (ZB602KL-4H006RU), 8*1.5ГГц, 32GB, 6" 2160*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, NFC, радио, 3 камеры 13+5/8Мпикс, Android 8, 76*159*8.45мм 180г, серебристый	 ' as product_description, 	13990,00	 as list_price,	13990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Archos Diamond Alpha, 8*1.8ГГц, 64GB, 5.2" 1920*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, NFC, радио, 4 камеры 13+13/16Мпикс, Android 6, 72.5*146*7.45мм 155г, черный	 ' as product_description, 	16990,00	 as list_price,	16990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim BQ BQ-4028 UP!, 2*1.3ГГц, 8GB, 4" 800*480, SD-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 5/2Мпикс, Android 6, 64*124*10.2мм 112г, черный	 ' as product_description, 	2790,00	 as list_price,	2790,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim BQ BQ-5001L Contact, 4*1.3ГГц, 8GB, 5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, NFC, радио, 2 камеры 5/2Мпикс, Android 7, 73*144*9.9мм 166г, синий	 ' as product_description, 	5490,00	 as list_price,	5490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim BQ BQ-5001L Contact, 4*1.3ГГц, 8GB, 5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, NFC, радио, 2 камеры 5/2Мпикс, Android 7, 73*144*9.9мм 166г, черный	 ' as product_description, 	5490,00	 as list_price,	5490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim BQ BQ-5035 VELVET, 4*1.3ГГц, 8GB, 5" 850*480, SD-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 8/5Мпикс, Android 7, 74*146*9.8мм, черный	 ' as product_description, 	4190,00	 as list_price,	4190,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim BQ BQ-5202 Space Lite, 4*1.3ГГц, 16GB, 5.2" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 13/8Мпикс, Android 7, 72.5*148.7*9.1мм 162г, черный	 ' as product_description, 	8490,00	 as list_price,	8490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim BQ BQ-5204 Strike Selfie, 4*1.3ГГц, 8GB, 5.2" 1280*720, SDHC-micro, 3G, GPS, BT, WiFi, радио, 2 камеры 16/13Мпикс, Android 7, 73*145.5*8.9мм 164г, серый	 ' as product_description, 	6490,00	 as list_price,	6490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim BQ BQ-5301 STRIKE VIEW, 4*1.3ГГц, 8GB, 5.34" 960*480, SDHC-micro, 3G, GPS, BT, WiFi, радио, 3 камеры 8+2/5Мпикс, Android 7, 70*146.3*8.65мм 145г, черный	 ' as product_description, 	4990,00	 as list_price,	4990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim BQ BQ-5340 CHOICE, 4*1.2ГГц, 8GB, 5.34" 960*480, SDHC-micro, 3G, GPS, BT, WiFi, радио, 2 камеры 5/5Мпикс, Android 7, 71*147*9.2мм 151г, глянцевый черный	 ' as product_description, 	4590,00	 as list_price,	4590,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim BQ BQ-5504 Strike Selfie Max, 4*1.2ГГц, 16GB, 5.5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 16/13Мпикс, Android 7, 76.8*155*8.9мм 171г, золотистый	 ' as product_description, 	9990,00	 as list_price,	9990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim BQ BQ-5504 Strike Selfie Max, 4*1.2ГГц, 16GB, 5.5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 16/13Мпикс, Android 7, 76.8*155*8.9мм 171г, серый	 ' as product_description, 	9990,00	 as list_price,	9990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim BQ BQ-5511L Bliss, 4*1.3ГГц, 8GB, 5.5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 8/5Мпикс, Android 7, 77.2*152.5*9.3мм 168г, черный	 ' as product_description, 	5990,00	 as list_price,	5990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim BQ BQ-5515L Fast, 4*1.5ГГц, 16GB, 5.5" 960*480, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 3 камеры 8+0.3/2Мпикс, Android 8.1, 71.6*150*9.2мм 165г, черный	 ' as product_description, 	6490,00	 as list_price,	6490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim BQ BQS-5503 Nice 2, 4*1.2ГГц, 8GB, 5.5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 13/5Мпикс, Android 7, 77.7*150.5*9.8мм 191г, черный	 ' as product_description, 	5990,00	 as list_price,	5990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Ginzzu R8 Dual, 2*1.3ГГц, 3.5" 480*320, SD-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 5/0.3Мпикс, Android 4.2, 66*122*17мм 123г, черный-оранжевый	 ' as product_description, 	4590,00	 as list_price,	4590,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Ginzzu S4510, 4*1.3ГГц, 4GB, 4.5" 854*480, SD-micro/SDHC-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 8/1.3Мпикс, Android 4.2, 65.6*133.7*9.2мм 131г, черный	 ' as product_description, 	5490,00	 as list_price,	5490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Ginzzu S5140, 4*1.3ГГц, 16GB, 5" 1280*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 20/5Мпикс, Android 5.1, 69.6*140.3*7.4мм 146г, черный	 ' as product_description, 	7539,00	 as list_price,	7539,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Highscreen Easy Power, 4*1.25ГГц, 16GB, 5" 1280*720, SD-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 8/2Мпикс, Android 7, 72*146*16.5мм 235г, черный	 ' as product_description, 	6290,00	 as list_price,	6290,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Highscreen Power Ice Evo, 4*1.25ГГц, 16GB, 5" 1280*720, SD-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 8/5Мпикс, Android 6, 71.4*144.5*8.7мм 158г, серебристый	 ' as product_description, 	6490,00	 as list_price,	6490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Huawei Honor 7c Pro (LND-L29), 8*1.8ГГц, 32GB, 5.99" 1440*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 3 камеры 13+2/8Мпикс, Android 8, 76.7*158.3*7.8мм 164г, черный	 ' as product_description, 	11990,00	 as list_price,	11990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Huawei Honor 7c Pro (LND-L29), 8*1.8ГГц, 32GB, 5.99" 1440*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 3 камеры 13+2/8Мпикс, Android 8, синий	 ' as product_description, 	11990,00	 as list_price,	11990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Huawei Nova 3i, 4*1.7+4*2.2ГГц, 64GB, 6.3" 2340*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 4 камеры 16+2/24+2Мпикс, Android 8, 75.2*157.6*7.6мм 169г, синий	 ' as product_description, 	17770,00	 as list_price,	17770,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Huawei Y5 2017, 4*1.4ГГц, 16GB, 5" 1280*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 8/5Мпикс, Android 6, 72*143.8*8.35мм 150г, серый	 ' as product_description, 	7490,00	 as list_price,	7490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Huawei Y5 Prime 2018, 4*1.5ГГц, 16GB, 5.45" 1440*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 5/13Мпикс, Android 8.1, 70.9*146.5*8.35мм 142г, синий	 ' as product_description, 	7990,00	 as list_price,	7990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Huawei Y5 Prime 2018, 4*1.5ГГц, 16GB, 5.45" 1440*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 5/13Мпикс, Android 8.1, 70.9*146.5*8.35мм 142г, черный	 ' as product_description, 	7990,00	 as list_price,	7990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Iconbit MERCURY QUAD FHD (NT-3506M), 4*1.5ГГц, 32GB, 5" 1920*1080, SDHC-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 13/2Мпикс, Android 4.2, 70*141*9мм 169г, черный	 ' as product_description, 	6138,00	 as list_price,	6138,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Iconbit mercury X, 2*1ГГц, 4GB, 4.5" 1280*720, SD-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 8/2Мпикс, Android 4.1, 68*129*9мм 121г, черный	 ' as product_description, 	3000,00	 as list_price,	3000,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim LG G4 (H818), 6*1.8ГГц, 32GB, 5.5" 2560*1440, 4G/3G, GPS, BT, WiFi, NFC, G-sensor, радио, 2 камеры 16/8Мпикс, Android 5.1, 76.2*148.9*9.8мм 155г, 434/20ч, коричневый	 ' as product_description, 	22900,00	 as list_price,	22900,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Lenovo Vibe C (PA300066RU), 4*1.1ГГц, 8GB, 5" 854*480, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 5/2Мпикс, Android 5.1, 71.8*143.5*8.95мм 166г, черный	 ' as product_description, 	5490,00	 as list_price,	5490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Lexand Capella (S5A3), 4*1.2ГГц, 4GB, 5" 1920*1080, SD-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 13/2Мпикс, Android 4.2  черный	 ' as product_description, 	5700,00	 as list_price,	5700,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Meizu M2 mini, 4*1.3ГГц, 16GB, 5" 1280*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 5.1, 68.9*140.1*8.7мм 131г, серый	 ' as product_description, 	6490,00	 as list_price,	6490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Meizu M3 Note, 4*1.8ГГц+4*1ГГц, 32GB, 5.5" 1920*1080, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 5.1, 75.5*153.6*8.2мм 163г, белый	 ' as product_description, 	8490,00	 as list_price,	8490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Meizu M5, 4*1.5ГГц+4*1ГГц, 16GB, 5.2" 1280*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 5.1, 72.8*147.2*8мм 138г, черный	 ' as product_description, 	7990,00	 as list_price,	7990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Meizu M5, 4*1.5ГГц+4*1ГГц, 32GB, 5.2" 1280*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 6, 72.8*147.2*8мм 138г, синий	 ' as product_description, 	8990,00	 as list_price,	8990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Meizu M5c, 4*1.3ГГц 16GB, 5" 1280*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 8/5Мпикс, Android 5.1, 70.51*144*8.3мм 135г, розовое золото	 ' as product_description, 	7450,00	 as list_price,	7450,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Meizu M5c, 4*1.3ГГц 16GB, 5" 1280*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 8/5Мпикс, Android 5.1, 70.51*144*8.3мм 135г, черный	 ' as product_description, 	6990,00	 as list_price,	6990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Meizu M6, 4*1.5ГГц+4*1ГГц, 16GB, 5.2" 1280*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/8Мпикс, Android 7, 72.8*148.2*8.3мм 143г, золотистый	 ' as product_description, 	8990,00	 as list_price,	8990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Meizu M6, 4*1.5ГГц+4*1ГГц, 16GB, 5.2" 1280*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/8Мпикс, Android 7, 72.8*148.2*8.3мм 143г, черный	 ' as product_description, 	8990,00	 as list_price,	8990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Meizu M6, 4*1.5ГГц+4*1ГГц, 32GB, 5.2" 1280*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/8Мпикс, Android 7, 72.8*148.2*8.3мм 143г, черный	 ' as product_description, 	10490,00	 as list_price,	10490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Meizu M8c, 4*1.4ГГц 16GB, 5.45" 1440*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/8Мпикс, Android 7, 70*146*8.5мм 140г, черный	 ' as product_description, 	7990,00	 as list_price,	7990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Meizu MX5, 8*2.2ГГц, 16GB, 5.5" 1920*1080, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 20.7/5Мпикс, Android 5.0, 74.7*149.9*7.6мм 149г, серый	 ' as product_description, 	15400,00	 as list_price,	15400,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Meizu U20, 4*1.8ГГц+4*1ГГц, 32GB, 5.5" 1920*1080, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 6, 75.4*153*7.7мм 158г, белый	 ' as product_description, 	7990,00	 as list_price,	7990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Micromax A092 Canvas Quad, 4*1.2ГГц, 8GB, 4" 800*480, SD-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 5/0.3Мпикс, Android 4.4, черный	 ' as product_description, 	3790,00	 as list_price,	3790,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Micromax A104 Canvas Fire 2, 4*1.3ГГц, 4GB, 4.5" 854*480, SD-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 5/0.3Мпикс, Android 4.4, 67*135*9.4мм 157г, черный	 ' as product_description, 	4990,00	 as list_price,	4990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Micromax A106 Canvas Viva, 4*1.3ГГц, 4GB, 4.7" 800*480, SD-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 5/2Мпикс, Android 4.4, 71.9*138.9*9.4мм 158г, черный	 ' as product_description, 	4290,00	 as list_price,	4290,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Micromax A114R Canvas Beat, 4*1.2ГГц, 4GB, 5" 960*540, SD-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 8/2Мпикс, Android 4.2, 72.4*147.9*8.6мм, 144г, серый	 ' as product_description, 	5000,00	 as list_price,	5000,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Micromax A200 Canvas Turbo Mini, 4*1.3ГГц, 4GB, 4.7" 1280*720, SD-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 8/5Мпикс, Android 4.2, 67.5*137.5*7.8мм, 110г, синий	 ' as product_description, 	5190,00	 as list_price,	5190,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Micromax A200 Canvas Turbo Mini, 4*1.3ГГц, 8GB, 4.7" 1280*720, SD-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 8/5Мпикс, Android 4.2, 67.5*137.5*7.8мм, 110г, черный	 ' as product_description, 	5290,00	 as list_price,	5290,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Micromax A290 Canvas Knight Cameo, 8*1.4ГГц, 8GB, 4.7" 1280*720, SD-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 8/5Мпикс, Android 4.2, черный	 ' as product_description, 	6990,00	 as list_price,	6990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Micromax D305 Bolt, 2*1ГГц, 4GB, 4" 800*480, SD-micro, GSM, GPS, BT, WiFi, G-sensor, радио, 2 камеры 2/0.3Мпикс, Android 5.1, черный	 ' as product_description, 	3300,00	 as list_price,	3300,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Motorola MOTO C (XT1750), MTK 4*1.1ГГц, 8GB, 5" 854*480, SD-micro, 3G, BT, WiFi, G-sensor, 2 камеры 5/2Мп., Android 7, 145.5*73.6*9мм 154г, белый	 ' as product_description, 	4990,00	 as list_price,	4990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Motorola MOTO C (XT1750), MTK 4*1.1ГГц, 8GB, 5" 854*480, SD-micro, 3G, BT, WiFi, G-sensor, 2 камеры 5/2Мп., Android 7, 145.5*73.6*9мм 154г, черный	 ' as product_description, 	4990,00	 as list_price,	4990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim OPPO A3s, 8*1.8ГГц, 16GB, 6.2" 1520*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 3 камеры 13+2/8Мпикс, Android 8, 75.6*156.2*8.2мм 143г, красный	 ' as product_description, 	12990,00	 as list_price,	12990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim OPPO A3s, 8*1.8ГГц, 16GB, 6.2" 1520*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 3 камеры 13+2/8Мпикс, Android 8, 75.6*156.2*8.2мм 143г, фиолетовый	 ' as product_description, 	12990,00	 as list_price,	12990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim OPPO A5, 8*1.8ГГц, 32GB, 6.2" 1520*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 3 камеры 13+2/8Мпикс, Android 8, 75.6*156.1*8.2мм 170г, красный	 ' as product_description, 	16990,00	 as list_price,	16990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim OPPO A5, 8*1.8ГГц, 32GB, 6.2" 1520*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 3 камеры 13+2/8Мпикс, Android 8, 75.6*156.1*8.2мм 170г, синий	 ' as product_description, 	16990,00	 as list_price,	16990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim OPPO A83, 8*2.5ГГц, 32GB, 5.7" 1440*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 13/8Мпикс, Android 7.1, 73.1*150.5*7.7мм 143г, золотистый	 ' as product_description, 	12990,00	 as list_price,	12990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim OPPO A83, 8*2.5ГГц, 32GB, 5.7" 1440*720, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 13/8Мпикс, Android 7.1, 73.1*150.5*7.7мм 143г, черный	 ' as product_description, 	12990,00	 as list_price,	12990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim OPPO F5 Youth, 8*2.5ГГц, 32GB, 6" 2160*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 13/16Мпикс, Android 7.1, 76*156.5*7.5мм 152г, золотистый	 ' as product_description, 	13990,00	 as list_price,	13990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim OPPO F5 Youth, 8*2.5ГГц, 32GB, 6" 2160*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 13/16Мпикс, Android 7.1, 76*156.5*7.5мм 152г, черный	 ' as product_description, 	13990,00	 as list_price,	13990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim OPPO F5, 8*2.5ГГц, 32GB, 6" 2160*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 16/20Мпикс, Android 7.1, 76*156.5*7.5мм 152г, черный	 ' as product_description, 	15990,00	 as list_price,	15990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim OPPO F5, 8*2.5ГГц, 64GB, 6" 2160*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 2 камеры 16/20Мпикс, Android 7.1, 76*156.5*7.5мм 152г, красный	 ' as product_description, 	19990,00	 as list_price,	19990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim OPPO RX17 Neo (CHP1893), 8*2.2ГГц, 128GB, 6.4" 2340*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 3 камеры 16+2/25Мпикс, Android 8.1, 75.5*158.3*7.4мм 156г, красный	 ' as product_description, 	29990,00	 as list_price,	29990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim OPPO RX17 Neo (CHP1893), 8*2.2ГГц, 128GB, 6.4" 2340*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, радио, 3 камеры 16+2/25Мпикс, Android 8.1, 75.5*158.3*7.4мм 156г, синий	 ' as product_description, 	29990,00	 as list_price,	29990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Philips Xenium (w336), 1*1ГГц, 2GB, 3.5" 480*320, SD-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, камера 3Мпикс, Android 4.0, 61*120*14мм 157г, 650/10ч, черный	 ' as product_description, 	4712,00	 as list_price,	4712,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Philips w536, 2*1ГГц, 4GB, 4" 800*480, SD-micro, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 5/0.3Мпикс, Android 4.0, 65*128*12мм 141г, красный	 ' as product_description, 	6390,00	 as list_price,	6390,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Prestigio Grace R7 (PSP7501D), 4*1.3ГГц, 16GB, 5" 1280*720, SD-micro, 3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/2Мпикс, Android 6, 70.9*142.5*8.3мм, серебристый	 ' as product_description, 	6800,00	 as list_price,	6800,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Prestigio Grace S5 LTE (PSP5551D), 4*1.3ГГц, 5.5" 1280*720, SD-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 8/5Мпикс, Android 5.1, 74.9*146.5*8.1мм 152г, синий	 ' as product_description, 	7490,00	 as list_price,	7490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Prestigio MUZE E5 LTE (PSP5545DUO), 4*1.3ГГц, 5.5" 1440*720, 16Гб, SD-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 8.1, 74.9*146.5*8.1мм 152г, синий	 ' as product_description, 	6990,00	 as list_price,	6990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Prestigio Multiphone MUZE D3 (PSP3530), 4*1.3ГГц, 8GB, 5.3" 1280*720, SD-micro, GSM/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 5, 74*148.8.3мм 165г, черный	 ' as product_description, 	7700,00	 as list_price,	7700,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Prestigio Multiphone MUZE G3 (PSP3511DUO), 4*1.3ГГц, 8GB, 5" 1280*720, SD-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 8/0.3Мпикс, Android 6, бордовый	 ' as product_description, 	4990,00	 as list_price,	4990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Prestigio Multiphone MUZE K5 (PSP5509DUO), 4*1ГГц, 8GB, 5" 1280*720, SD-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 8/2Мпикс, Android 5.1, синий	 ' as product_description, 	6190,00	 as list_price,	6190,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Prestigio Wize Q3 (PSP3471DUO), 4*1.2ГГц, 5" 960*480, 8Гб, SD-micro, 3G, GPS, BT, WiFi, G-sensor, 2 камеры 8/2Мпикс, Android 7, 74.9*146.5*8.1мм 152г, красный	 ' as product_description, 	4390,00	 as list_price,	4390,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Samsung Galaxy J1 2016 (SM-J120FZDDSER), 4*1.3ГГц, 8GB, 4.5" 800*480, SD-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 5/2Мпикс, Android 5.1, 69.3*132.6*8.9мм 131г, золотистый	 ' as product_description, 	6990,00	 as list_price,	6990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Samsung Galaxy J1 mini prime (SM-J106FZKDSER), 4*1.5ГГц, 8GB, 4" 800*480, SD-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 5/0.3Мпикс, Android 6, черный	 ' as product_description, 	5990,00	 as list_price,	5990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Samsung Galaxy J2 Prime (SM-G532FZDDSER), 4*1.4ГГц, 8GB, 5" 960*540, SD-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 8/5Мпикс, Android 5.1, 72.1*144.8*8.9мм 160г, золотистый	 ' as product_description, 	7990,00	 as list_price,	7990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Samsung Galaxy J7 Neo (SM-J701FZKDSER), 8*1.6ГГц, 16GB, 5.5" 1280*720, SD-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 7, 78.6*152.4*7.6мм, черный	 ' as product_description, 	11490,00	 as list_price,	11490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Samsung Galaxy S8+ (SM-G955FZKDSER), 8*2.3ГГц, 64GB, 6.2" 2960*1440, SD-micro, 4G/3G, GPS, BT, Wi-Fi, NFC, G-sensor, 2 камеры 12/8Мпикс, Android 7, 73*160*8.1мм 173г, черный	 ' as product_description, 	49990,00	 as list_price,	49990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Vertex Impress Baccara, 4*1.25ГГц, 16GB, 5.5" 1280*720, SD-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 3 камеры 13+5/8Мпикс, Android 7, 72*151*10мм 184г, черный	 ' as product_description, 	6290,00	 as list_price,	6290,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Vertex Impress Tor, 4*1.1ГГц, 8GB, 5" 1280*720, SD-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 13/5Мпикс, ip68, Android 6, 72*151*10мм 184г, черный	 ' as product_description, 	8190,00	 as list_price,	8190,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Xiaomi Redmi 3S, 8*1.4ГГц, 32GB, 5" 1280*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 6.1, 69.6*139.3*8.5мм 144г, золотистый	 ' as product_description, 	13500,00	 as list_price,	13500,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Xiaomi Redmi 4X, 8*1.4ГГц, 16GB, 5" 1280*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 6.1, 69.9*139.2*8.6мм 150г, золотистый	 ' as product_description, 	11540,00	 as list_price,	11540,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Xiaomi Redmi 4X, 8*1.4ГГц, 32GB, 5" 1280*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 6.1, 69.9*139.2*8.6мм 150г, золотистый	 ' as product_description, 	11990,00	 as list_price,	11990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Xiaomi Redmi 5, 8*1.8ГГц, 32GB, 5.7" 1440*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 12/5Мпикс, Android 7, 72.8*151.8*7.7мм 157г, голубой	 ' as product_description, 	11490,00	 as list_price,	11490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Xiaomi Redmi 5, 8*1.8ГГц, 32GB, 5.7" 1440*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 12/5Мпикс, Android 7, 72.8*151.8*7.7мм 157г, золотистый	 ' as product_description, 	11490,00	 as list_price,	11490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Xiaomi Redmi 6A, 4*2ГГц 16GB, 5.45" 1440*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 8, 71.5*147.5*8.3мм 145г, черный	 ' as product_description, 	7490,00	 as list_price,	7490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Xiaomi Redmi 6A, 4*2ГГц 16GB, 5.45" 1440*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 8, 71.5*147.5*8.5мм 145г, золотистый	 ' as product_description, 	7490,00	 as list_price,	7490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Xiaomi Redmi Note 3 Pro, 6*1.8ГГц, 16GB, 5.5" 1920*1080, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 16/5Мпикс, Android 5.1, 76*150*8.65мм 164г, серебристый	 ' as product_description, 	12450,00	 as list_price,	12450,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Xiaomi Redmi Note 5A Prime, 8*1.4ГГц, 64GB, 5.5" 1280*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/16Мпикс, Android 7.1, 76.2*153*7.7мм 153г, серый	 ' as product_description, 	13990,00	 as list_price,	13990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон 2*sim Xiaomi Redmi Note 5A, 4*1.4ГГц, 16GB, 5.5" 1280*720, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 7.1, 76.2*153*7.7мм 153г, серый	 ' as product_description, 	8440,00	 as list_price,	8440,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон ASUS Padfone S (PF500KL), 4*2.3ГГц, 16GB, 5" 1920*1080, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 13/2Мпикс, Android 4.4, черный	 ' as product_description, 	9990,00	 as list_price,	9990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон ASUS ZenFone Zoom (ZX551ML-1A074RU), 4*2.5, 128GB, 5.5" 1920*1080, SDHC-micro, 4G/3G, GPS, BT, WiFi, NFC, 2 камеры 13/5Мпикс, Android 5, 78.8*158.9*11.9мм, 185г, черный	 ' as product_description, 	13490,00	 as list_price,	13490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Apple iPhone 5s (FF354RU/A), 2*1.3ГГц, 16GB, 4" 1136*640, GSM/3G/4G, GPS, BT, WiFi, G-sensor, 2 камеры 8/1.2Мпикс, 59*124*8мм 112г, 250/8ч, золотистый (как новый)	 ' as product_description, 	18490,00	 as list_price,	18490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Apple iPhone 5s (ME436), 2*1.3ГГц, 32GB, 4" 1136*640, GSM/3G/4G, GPS, BT, WiFi, G-sensor, 2 камеры 8/1.2Мпикс, 59*124*8мм 112г, 250/8ч, серебристый	 ' as product_description, 	19077,00	 as list_price,	19077,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Apple iPhone 5s (ME437), 2*1.3ГГц, 32GB, 4" 1136*640, GSM/3G/4G, GPS, BT, WiFi, G-sensor, 2 камеры 8/1.2Мпикс, 59*124*8мм 112г, 250/8ч, золотистый	 ' as product_description, 	18990,00	 as list_price,	18990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Apple iPhone 5s (ME439), 2*1.3ГГц, 64GB, 4" 1136*640, GSM/3G/4G, GPS, BT, WiFi, G-sensor, 2 камеры 8/1.2Мпикс, 59*124*8мм 112г, 250/8ч, серебристый	 ' as product_description, 	21870,00	 as list_price,	21870,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Apple iPhone 5s, 2*1.3ГГц, 16GB, 4" 1136*640, GSM/3G/4G, GPS, BT, WiFi, G-sensor, 2 камеры 8/1.2Мпикс, 59*124*8мм 112г, 250/8ч, золотистый, восстановленный	 ' as product_description, 	9990,00	 as list_price,	9990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Apple iPhone 5s, 2*1.3ГГц, 16GB, 4" 1136*640, GSM/3G/4G, GPS, BT, WiFi, G-sensor, 2 камеры 8/1.2Мпикс, 59*124*8мм 112г, 250/8ч, серебристый, восстановленный	 ' as product_description, 	9990,00	 as list_price,	9990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Apple iPhone 5s, 2*1.3ГГц, 16GB, 4" 1136*640, GSM/3G/4G, GPS, BT, WiFi, G-sensor, 2 камеры 8/1.2Мпикс, 59*124*8мм 112г, 250/8ч, серый, восстановленный	 ' as product_description, 	9990,00	 as list_price,	9990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Apple iPhone 6 (MG4C2RU/A), 2*1.4ГГц, 128GB, 4.7" 1334*750, GSM/3G/4G, GPS, BT, WiFi, NFC, G-sensor, 2 камеры 8/1.2Мпикс, 67*138.1*6.9мм 129г, 250/8ч, серебристый	 ' as product_description, 	33826,00	 as list_price,	33826,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Apple iPhone 6 (MG4E2RU/A), 2*1.4ГГц, 128GB, 4.7" 1334*750, GSM/3G/4G, GPS, BT, WiFi, NFC, G-sensor, 2 камеры 8/1.2Мпикс, 67*138.1*6.9мм 129г, 250/8ч, золотистый	 ' as product_description, 	29990,00	 as list_price,	29990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Apple iPhone 6 Plus (MGAC2RU/A), 2*1.4ГГц, 128GB, 5.5" 1920*1080, GSM/3G/4G, GPS, BT, WiFi, NFC, G-sensor, 2 камеры 8/1.2Мпикс, 77.8*158.1*7.1мм 172г, 384/24ч, серый	 ' as product_description, 	30990,00	 as list_price,	30990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Apple iPhone 6, 2*1.4ГГц, 16GB, 4.7" 1334*750, GSM/3G/4G, GPS, BT, WiFi, NFC, G-sensor, 2 камеры 8/1.2Мпикс, 67*138.1*6.9мм 129г, 250/8ч, серебристый, восстановленный	 ' as product_description, 	15635,00	 as list_price,	15635,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Apple iPhone 6, 2*1.4ГГц, 64GB, 4.7" 1334*750, GSM/3G/4G, GPS, BT, WiFi, NFC, G-sensor, 2 камеры 8/1.2Мпикс, 67*138.1*6.9мм 129г, 250/8ч, серый, восстановленный	 ' as product_description, 	18990,00	 as list_price,	18990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Apple iPhone 7 (FN982RU/A), 4*2.34ГГц, 256GB, 4.7" 1334*750, GSM/3G/4G, GPS, BT, WiFi, NFC, G-sensor, 2 камеры 12/7Мпикс, 67.1*138.3*7.1мм 138г, серебристый, как новый	 ' as product_description, 	35490,00	 as list_price,	35490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Apple iPhone 7 (MN8Y2), 4*2.34ГГц, 32GB, 4.7" 1334*750, GSM/3G/4G, GPS, BT, WiFi, NFC, G-sensor, 2 камеры 12/7Мпикс, 67.1*138.3*7.1мм 138г, серебристый	 ' as product_description, 	38990,00	 as list_price,	38990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Apple iPhone 7, 4*2.34ГГц, 128GB, 4.7" 1334*750, GSM/3G/4G, GPS, BT, WiFi, NFC, G-sensor, 2 камеры 12/7Мпикс, 67.1*138.3*7.1мм 138г, золотистый, восстановленный	 ' as product_description, 	32990,00	 as list_price,	32990,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Lenovo A606, 4*1.2ГГц, 8GB, 5" 854*480, SD-micro/SDHC-micro, 4G/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 8/2Мпикс, 73.2*141.5*9.1мм 170г, Android 4.4, белый	 ' as product_description, 	5490,00	 as list_price,	5490,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Lenovo Vibe X2, 4*2ГГц+4*1.69ГГц, 32GB, 5" 1920*1080, SD-micro, 4G/3G, GPS, BT, WiFi, G-sensor, 2 камеры 13/5Мпикс, Android 4.4, 68.6*140.2*7.27мм, 120г, белый	 ' as product_description, 	12013,00	 as list_price,	12013,00	 as min_price,  interval '12' month as warranty_period from dual union all
    select '	Смартфон Lenovo Vibe Z (K910L), 4*2.2ГГц, 16GB, 5.5" 1920*1080, GSM/3G, GPS, BT, WiFi, G-sensor, радио, 2 камеры 13/5Мпикс, Android 4.3, 77*149*7.9мм 145г, серый	 ' as product_description, 	10490,00	 as list_price,	10490,00	 as min_price,  interval '12' month as warranty_period from dual 
  )
;
