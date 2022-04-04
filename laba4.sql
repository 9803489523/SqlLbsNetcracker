/*
1.В анонимном PL/SQL блоке распечатать все пифагоровы числа, 
меньшие 25 (для печати использовать пакет dbms_output, процедуру put_line).
*/
SET SERVEROUTPUT ON;
declare
  c_length int := 24;
begin
  for i in 1..c_length loop
    for j in i..c_length loop
      for k in j..c_length loop
        if i*i+j*j=k*k then
          dbms_output.put_line(i||', '||j||', '|| k);
        end if;
      end loop;
    end loop;
  end loop;
end;
/

/*
  2.Переделать предыдущий пример, чтобы для определения, что 3 числа пифагоровы использовалась функция.
*/
create or replace function f_check_pifagor(v1 int,v2 int,v3 int ) return boolean
is
  begin
    return v1*v1+v2*v2=v3*v3;
  end;
  
SET SERVEROUTPUT ON;
declare
  c_length int:=24;
 begin
  for i in 1..c_length loop
    for j in i..c_length loop
      for k in j..c_length loop
        if f_check_pifagor(i,j,k) then
          dbms_output.put_line(i||', '||j||', '|| k);
        end if;
      end loop;
    end loop;
  end loop;
end; 
/*
3.Написать хранимую процедуру, которой передается ID сотрудника и которая увеличивает ему зарплату на 10%, если в 2000 году у сотрудника были продажи. 
Использовать выборку количества заказов за 2000 год в переменную. А затем, если переменная больше 0, выполнить update данных.
*/
create or replace procedure pr_salary_increasing(p_id employees.employee_id%type)
is
  order_quanity int;
begin
  select count(o.order_id)
    into order_quanity
    from orders o
    where o.sales_rep_id = p_id and
          date'2000-01-01' <= o.order_date and o.order_date < date'2001-01-01';
    if order_quanity>0 then
      update employees e
        set e.salary = e.salary * 1.1
        where e.employee_id = p_id;
    end if;
end;

SET SERVEROUTPUT ON;
declare
  order_amount int;
  salary employees.salary%type;
  emp_id employees.employee_id%type := 158;
begin
  select e.salary
    into salary
    from employees e
    where e.employee_id = emp_id;
  dbms_output.put_line(salary);
  pr_salary_increasing(emp_id);
  select  e.salary
    into  salary
    from  employees e
    where e.employee_id = emp_id;
  dbms_output.put_line(salary);
end;

/*
4.Проверить корректность данных о заказах, а именно, что поле ORDER_TOTAL равно сумме UNIT_PRICE * QUANTITY 
по позициям каждого заказа. Для этого создать хранимую процедуру, в которой будет в цикле for проход по всем 
заказам, далее по конкретному заказу отдельным select-запросом будет выбираться сумма по позициям данного заказа 
и сравниваться с ORDER_TOTAL. Для «некорректных» заказов распечатать код заказа, дату заказа, заказчика и менеджера.
*/

create or replace procedure pr_check_total
is
  total orders.order_total%type;
  true_price number;
begin
  for ord in (
    select *
      from orders
    ) loop
    total := ord.order_total;
    select  sum(oi.unit_price * oi.quantity)
      into true_price
      from  order_items oi
      where oi.order_id=ord.order_id;
      if true_price!=total then
        dbms_output.put_line(ord.order_id || ' ' || ord.order_date || ' ' || ord.customer_id);
      end if;
    end loop;        
end;

SET SERVEROUTPUT ON;
begin
    pr_check_total;
end;

/*
5.Переписать предыдущее задание с использованием явного курсора.
*/
create or replace procedure pr_cursor_check_total
is
  cursor cur_total_check is
    select o.order_id,
           oi.real_price,
           o.order_total,
           o.customer_id,
           o.order_date
        from orders o
            join (
              select sum(oi.unit_price * oi.quantity) as real_price,
                     oi.order_id
                from  order_items oi
                group by oi.order_id
              ) oi on oi.order_id = o.order_id;     
    v_ord cur_total_check%rowtype;
    begin
      open cur_total_check;
      loop
        fetch cur_total_check into v_ord;
        exit when cur_total_check%notfound;
        if v_ord.order_total <> v_ord.real_price then
          dbms_output.put_line(v_ord.order_id || ' ' || v_ord.order_date || ' ' || v_ord.customer_id);
        end if;
      end loop;        
end;

SET SERVEROUTPUT ON;
begin
  pr_cursor_check_total;
end;


/*
6.Написать функцию, в которой будет создан тестовый клиент, которому будет сделан заказ на текущую дату из 
одной позиции каждого товара на складе. Имя тестового клиента и ID склада передаются в качестве параметров.
Функция возвращает ID созданного клиента.
*/
create or replace function fn_create_order(
     p_first_name in customers.cust_first_name%type,
     p_last_name in customers.cust_last_name%type,
     p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type
  is 
    v_customer_id customers.customer_id%type;
    v_order_id orders.order_id%type;
    v_line_item_id order_items.line_item_id%type := 1;
    v_order_total orders.order_total%type := 0;
  begin
    insert into customers (cust_first_name, cust_last_name)
      values (p_first_name, p_last_name)
      returning customer_id into v_customer_id;
    insert into orders (order_date, customer_id)
      values (sysdate, v_customer_id)
      returning order_id into v_order_id;
    for i_product in (
      select pi.*
        from  inventories inv
              join product_information pi on 
                pi.product_id = inv.product_id
        where inv.warehouse_id = p_warehouse_id and
              inv.quantity_on_hand > 0
    ) loop
      insert into order_items (order_id, line_item_id, product_id, unit_price, quantity)
        values (v_order_id, v_line_item_id, i_product.product_id, i_product.list_price, 1);
      v_line_item_id := v_line_item_id + 1;
      v_order_total := v_order_total + i_product.list_price;
    end loop;
    update  orders 
       set  order_total = v_order_total
      where order_id = v_order_id;
    return v_customer_id;
  end;
  
begin
    dbms_output.put_line(fn_create_order('denis', 'ivanov', 1));
end;


/*
7.Добавить в предыдущую функцию проверку на существование склада с переданным ID. Для этого выбрать склад 
в переменную типа «запись о складе» и перехватить исключение no_data_found, если оно возникнет. 
В обработчике исключения выйти из функции, вернув null.
*/
create or replace function fn_create_order_with_wcheck(
     p_first_name in customers.cust_first_name%type,
     p_last_name in customers.cust_last_name%type,
     p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type
  is 
    v_warehouse warehouses%rowtype;
    v_customer_id customers.customer_id%type;
    v_order_id orders.order_id%type;
    v_line_item_id order_items.line_item_id%type := 1;
    v_order_total orders.order_total%type := 0;
  begin
    begin
      select  w.*
        into  v_warehouse
        from  warehouses w
        where w.warehouse_id = p_warehouse_id;
    exception
    when no_data_found then
      return null;
    end;
    insert into customers (cust_first_name, cust_last_name)
      values (p_first_name, p_last_name)
      returning customer_id into v_customer_id;
    insert into orders (order_date, customer_id)
      values (sysdate, v_customer_id)
      returning order_id into v_order_id;
    for prod in (select pi.*
                        from  inventories i
                          join product_information pi 
                            on pi.product_id = i.product_id
                        where i.warehouse_id = p_warehouse_id and
                              i.quantity_on_hand > 0) loop
      insert into order_items (order_id, line_item_id, product_id, unit_price, quantity)
        values (v_order_id, v_line_item_id, prod.product_id, prod.list_price, 1);
      v_line_item_id := v_line_item_id + 1;
      v_order_total := v_order_total + prod.list_price;
    end loop;
    update  orders 
         set  order_total = v_order_total
        where order_id = v_order_id;
      return v_customer_id;
    return v_customer_id;
  end;
  
begin
    dbms_output.put_line( fn_create_order_with_wcheck('denis', 'ivanov', 1));
end
;


/*
8.Написанные процедуры и функции объединить в пакет FIRST_PACKAGE.
*/
create or replace package FIRST_PACKAGE as 

function f_check_pifagor(v1 int,v2 int,v3 int ) return boolean;

procedure pr_salary_increasing(p_id employees.employee_id%type);

procedure pr_check_total;

procedure pr_cursor_check_total;

function fn_create_order(
     p_first_name in customers.cust_first_name%type,
     p_last_name in customers.cust_last_name%type,
     p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type;
  
function fn_create_order_with_wcheck(
     p_first_name in customers.cust_first_name%type,
     p_last_name in customers.cust_last_name%type,
     p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type;
  
end FIRST_PACKAGE;

/*


*/
create or replace package body FIRST_PACKAGE as 


function f_check_pifagor(v1 int,v2 int,v3 int ) return boolean
is
  begin
    return v1*v1+v2*v2=v3*v3;
  end;
  
  
procedure pr_salary_increasing(p_id employees.employee_id%type)
is
  order_quanity int;
begin
  select count(o.order_id)
    into order_quanity
    from orders o
    where o.sales_rep_id = p_id and
          date'2000-01-01' <= o.order_date and o.order_date < date'2001-01-01';
    if order_quanity>0 then
      update employees e
        set e.salary = e.salary * 1.1
        where e.employee_id = p_id;
    end if;
end;


procedure pr_check_total
is
  total orders.order_total%type;
  true_price number;
begin
  for ord in (
    select *
      from orders
    ) loop
    total := ord.order_total;
    select  sum(oi.unit_price * oi.quantity)
      into true_price
      from  order_items oi
      where oi.order_id=ord.order_id;
      if true_price!=total then
        dbms_output.put_line(ord.order_id || ' ' || ord.order_date || ' ' || ord.customer_id);
      end if;
    end loop;        
end;


procedure pr_cursor_check_total
is
  cursor cur_total_check is
    select o.order_id,
           oi.real_price,
           o.order_total,
           o.customer_id,
           o.order_date
        from orders o
            join (
              select sum(oi.unit_price * oi.quantity) as real_price,
                     oi.order_id
                from  order_items oi
                group by oi.order_id
              ) oi on oi.order_id = o.order_id;     
    v_ord cur_total_check%rowtype;
    begin
      open cur_total_check;
      loop
        fetch cur_total_check into v_ord;
        exit when cur_total_check%notfound;
        if v_ord.order_total <> v_ord.real_price then
          dbms_output.put_line(v_ord.order_id || ' ' || v_ord.order_date || ' ' || v_ord.customer_id);
        end if;
      end loop;        
end;


function fn_create_order(
     p_first_name in customers.cust_first_name%type,
     p_last_name in customers.cust_last_name%type,
     p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type
  is 
    v_customer_id customers.customer_id%type;
    v_order_id orders.order_id%type;
    v_line_item_id order_items.line_item_id%type := 1;
    v_order_total orders.order_total%type := 0;
  begin
    insert into customers (cust_first_name, cust_last_name)
      values (p_first_name, p_last_name)
      returning customer_id into v_customer_id;
    insert into orders (order_date, customer_id)
      values (sysdate, v_customer_id)
      returning order_id into v_order_id;
    for i_product in (
      select pi.*
        from  inventories inv
              join product_information pi on 
                pi.product_id = inv.product_id
        where inv.warehouse_id = p_warehouse_id and
              inv.quantity_on_hand > 0
    ) loop
      insert into order_items (order_id, line_item_id, product_id, unit_price, quantity)
        values (v_order_id, v_line_item_id, i_product.product_id, i_product.list_price, 1);
      v_line_item_id := v_line_item_id + 1;
      v_order_total := v_order_total + i_product.list_price;
    end loop;
    update  orders 
       set  order_total = v_order_total
      where order_id = v_order_id;
    return v_customer_id;
  end;
  
  
function fn_create_order_with_wcheck(
     p_first_name in customers.cust_first_name%type,
     p_last_name in customers.cust_last_name%type,
     p_warehouse_id in warehouses.warehouse_id%type
  ) return customers.customer_id%type
  is 
    v_warehouse warehouses%rowtype;
    v_customer_id customers.customer_id%type;
    v_order_id orders.order_id%type;
    v_line_item_id order_items.line_item_id%type := 1;
    v_order_total orders.order_total%type := 0;
  begin
    begin
      select  w.*
        into  v_warehouse
        from  warehouses w
        where w.warehouse_id = p_warehouse_id;
    exception
    when no_data_found then
      return null;
    end;
    insert into customers (cust_first_name, cust_last_name)
      values (p_first_name, p_last_name)
      returning customer_id into v_customer_id;
    insert into orders (order_date, customer_id)
      values (sysdate, v_customer_id)
      returning order_id into v_order_id;
    for prod in (select pi.*
                        from  inventories i
                          join product_information pi 
                            on pi.product_id = i.product_id
                        where i.warehouse_id = p_warehouse_id and
                              i.quantity_on_hand > 0) loop
      insert into order_items (order_id, line_item_id, product_id, unit_price, quantity)
        values (v_order_id, v_line_item_id, prod.product_id, prod.list_price, 1);
      v_line_item_id := v_line_item_id + 1;
      v_order_total := v_order_total + prod.list_price;
    end loop;
    update  orders 
         set  order_total = v_order_total
        where order_id = v_order_id;
      return v_customer_id;
    return v_customer_id;
  end;
  
end FIRST_PACKAGE;
/*
9.Написать функцию, которая возвратит таблицу (table of record), содержащую информацию о частоте встречаемости 
отдельных символов во всех названиях (и описаниях) товара на заданном языке (передается код языка, а также параметр, 
указывающий, учитывать ли описания товаров). Возвращаемая таблица состоит из 2-х полей: символ, частота встречаемости
в виде частного от кол-ва данного символа к количеству всех символов в названиях (и описаниях) товара.
*/

create type tp_char_result as 
object(
  ch nchar(1), 
  freq number
);
create type tp_char_result_table as
table of tp_char_result;
create or replace function fn_char_freq(
  p_lang_id in product_descriptions.language_id%type,
  p_description in int
) return tp_char_result_table
is 
  type tp_char_result_indexed_table is 
    table of tp_char_result index by binary_integer;
  v_result_table tp_char_result_table;
  v_indexed_table tp_char_result_indexed_table;
  v_ch nchar(1);
  v_code binary_integer;
begin 
  v_result_table := tp_char_result_table();
  for i_pd in (select  *
                 from  product_descriptions pd
                 where pd.language_id = p_lang_id
  ) loop
    for i_l in 1..length(i_pd.translated_name) loop
      v_ch := substr(i_pd.translated_name, i_l, 1);
      v_code := ascii(v_ch);
      if not v_indexed_table.exists(v_code) then
        v_indexed_table(v_code) := tp_char_result(v_ch, 0);
      end if;
      v_indexed_table(v_code).freq := v_indexed_table(v_code).freq + 1;
    end loop;
  end loop; 
  if p_description>0 then 
    for i_pd in (select  *
                   from  product_descriptions pd
                   where pd.language_id = p_lang_id
    ) loop
      for i_l in 1..length(i_pd.translated_description) loop
        v_ch := substr(i_pd.translated_description, i_l, 1);
        v_code := ascii(v_ch);
        if not v_indexed_table.exists(v_code) then
          v_indexed_table(v_code) := tp_char_result(v_ch, 0);
        end if;
        v_indexed_table(v_code).freq := v_indexed_table(v_code).freq + 1;
      end loop;
    end loop;
  end if;  
  v_code := v_indexed_table.first;
  while v_code is not null
    loop
      v_result_table.extend(1);
      v_result_table(v_result_table.last) := v_indexed_table(v_code);
      v_code := v_indexed_table.next(v_code);
    end loop;
  return v_result_table;
end;
declare
  v_result tp_char_result_table;
begin
  v_result := fn_char_freq('RU', true);
  for i in 1..v_result.count
    loop
      dbms_output.put_line(v_result(i).ch || ' ' || v_result(i).freq);
    end loop;
end;
select  *
  from  table(cast(fn_char_freq('RU', 1) as tp_char_result_table))
;
/*
10.Написать функцию, которой передается sys_refcursor и которая по данному курсору формирует HTML-таблицу, 
содержащую информацию из курсора. Тип возвращаемого значения – clob.
*/
declare
  v_cur sys_refcursor;
  v_res clob;
  
  function create_html_table(p_cur in out sys_refcursor)
    return clob
  is
    v_cur sys_refcursor := p_cur;
    v_cn integer;
    v_columns_desc dbms_sql.desc_tab2;
    v_columns_count integer;
    v_temp integer;
    v_res clob;
    v_str varchar2(1000);
  begin
    dbms_lob.createtemporary(v_res, true); 
    v_cn := dbms_sql.to_cursor_number(v_cur);
    dbms_sql.describe_columns2(v_cn, v_columns_count, v_columns_desc);
    for i_index in 1 .. v_columns_count loop
      dbms_sql.define_column(v_cn, i_index, v_str, 1000);
    end loop; 
    dbms_lob.append(v_res, '<table><tr>');
    for i_index in 1..v_columns_count loop
      dbms_lob.append(v_res, '<th>' || v_columns_desc(i_index).col_name || '</th>');
    end loop;
    dbms_lob.append(v_res, '</tr>'); 
    loop
      v_temp:=dbms_sql.fetch_rows(v_cn);
      exit when v_temp = 0;
      dbms_lob.append(v_res, '<tr>');
      for i_index in 1 .. v_columns_count
        loop
          dbms_sql.column_value(v_cn, i_index, v_str);
          dbms_lob.append(v_res, '<td>' || v_str || '</td>');
        end loop;
      dbms_lob.append(v_res, '</tr>');
    end loop;  
    dbms_lob.append(v_res, '</table>');
    return v_res;
  end;
  
begin
  open v_cur for
    select c.* 
      from countries c;
  v_res := create_html_table(v_cur);
  dbms_output.put_line(v_res);
end;
