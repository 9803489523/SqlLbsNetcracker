/*
 1.�������� ������, ��������� ��� ���������� � �������������. ����������� �� ����
������������.
*/
select   d.*
    from departments d
    order by d.department_id
;
/*
2.�������� ������, ���������� ID, ���+������� (� ���� ������ ������� ����� ������)
� ����� ����������� ����� ���� ��������. (������������ ������������ ����� �
�������������� ������� � ������ � �������� �� �NAME�). ����������� �� ����
�������.
*/
select   c.customer_id,
         c.cust_first_name ||' '||c.cust_last_name as NAME,
         c.cust_email
    from customers c
    order by c.customer_id
;
/*
 3.�������� ������, ��������� �����������, �������� ������� �� ��� ����� � ���������
�� 100 �� 200 ���. ���., ���������� �� �� ���������� ���������, �������� (�� �������
� �������) � �������. ��������� ������ ������ �������� �������, ���, ���������
(��� ���������), email, �������, �������� �� ����� �� ������� �������. ����� �������,
��� � ��� ������������� ����� ���������������: � �������� �� ��� �� 100 �� 150 ���.
���. ����� ���������� 30%, ���� � 35%. ��������� ��������� �� ������ ���.
����������� ������������ between � case.
*/
select    e.last_name,
          e.first_name,
          e.job_id,
          e.email,
          e.phone_number,
          case
              when e.salary*12 between 100000 and 150000 then
                  round(e.salary*0.3,0)
              when e.salary*12>150000 then
                  round(e.salary*0.35,0)
              end
         
          as salary
    from  employees e
    where e.salary*12>100000 and e.salary*12<200000
    order by e.job_id,
             case
                when e.salary*12 between 100000 and 150000 then
                    round(e.salary*0.3,0)
                when e.salary*12>150000 then
                    round(e.salary*0.35,0)
                end,
             e.last_name
;
/*
 4.������� ������ � ���������������� DE, IT ��� RU. ������������� ������� �� ����
�������, ��������� �������. ����������� �� �������� ������.
*/
select    c.country_id as "��� ������",
          c.country_name as "�������� ������"
    from  countries c
    where c.country_id='DE' or c.country_id='IT'
    order by c.country_name
;
/*
 5.������� ���+������� �����������, � ������� � ������� ������ ����� �a� (���������),
� � ����� ������������ ����� �d� (�� �����, � ����� ��������). ����������� �� �����.
������������ �������� like � ������� ���������� � ������� ��������.
*/
select    e.first_name||' '||e.last_name as employee
    from  employees e
    where e.last_name like'_a%'and lower(e.first_name) like '%d%'
    order by e.first_name
;
/*
 6.������� ����������� � ������� ������� ��� ��� ������ 5 ��������. �����������
������ �� ��������� ����� ������� � �����, ����� �� ����� �������, ����� ������ ��
�������, ����� ������ �� �����.
*/
select    e.*
    from  employees e
    where length(e.last_name)<5 or length(e.first_name)<5
    order by length(e.last_name)+length(e.first_name),
             length(e.last_name),
             e.last_name,
             e.first_name
;
/*
 7.������� ��������� � ������� �� ����������� (������� ��������, �� ������� �����
�������-�������������� ����������� � ������������ �������). ����� ���������
��������� ������ ���� �������, � ������ ���������� �������� ����������� �� ����
���������. ������� ������� ��� ���������, �������� ���������, ������� ��������
����� �������, ����������� �� �����. ������� ����� ��������������� ������� � 18%.
*/
select   j.job_id,
         j.job_title,
         round((((j.min_salary+j.max_salary)/2)*0.82),-2) as AVG_SALARY
    from jobs j
    order by (j.min_salary+j.max_salary)/2 desc,j.job_id
;
/*
 8.����� �������, ��� ��� ������� ������� �� ��������� A, B, C. ��������� A � ������� �
��������� ������� >= 3500, B >= 1000, C � ��� ���������. ������� ���� ��������,
���������� �� �� ��������� � �������� ������� (������� ������� ��������� A), �����
�� �������. ������� ������� �������, ���, ���������, �����������. � �����������
��� �������� ��������� A ������ ���� ������ ���������, VIP-��������, ���
��������� �������� ����������� ������ �������� ������ (NULL).
*/
select   c.cust_last_name, 
         c.cust_first_name,
         case 
             when c.credit_limit<1000 then
                 'C'
             when c.credit_limit>=1000 and c.credit_limit<3500 then
                 'B'
             when c.credit_limit>=3500 then
                 'A'
             end
         as CATEGORY,
         case 
             when c.credit_limit >= 3500 then 
                 '��������, VIP-�������'
             else
                 null 
             end 
         as COMMENTS
    from customers c
    order by case 
                when c.credit_limit<1000 then
                    'C'
                when c.credit_limit>=1000 and c.credit_limit<3500 then
                    'B'
                when c.credit_limit>=3500 then
                    'A'
                end,
             c.cust_last_name
;
/*
 9.������� ������ (�� �������� �� �������), � ������� ���� ������ � 1998 ����. ������
�� ������ ����������� � ������ ���� �����������. ������������ ����������� ��
������� extract �� ���� ��� ���������� ������������ ������� � decode ��� ������
�������� ������ �� ��� ������. ���������� �� ������������.
*/
select   decode(
            extract(
              month from o.order_date),
              1,'������',
              2,'�������',
              3,'����',
              4,'������',
              5,'���',
              6,'����',
              7,'����',
              8,'������',
              9,'��������',
              10,'�������',
              11,'������',
              12,'�������'
              ) 
          as month
    from  orders o
    where extract(year from o.order_date)=1998 and 
          o.order_status>0
    group by extract(month from o.order_date)
    order by extract(month from o.order_date)   
;
    
/*
 10.�������� ���������� ������, ��������� ��� ��������� �������� ������ �������
to_char (������� ��� ������� nls_date_language 3-� ����������). ������ �����������
������������ distinct, ���������� �� ������������.
*/
select    distinct to_char(o.order_date,'month','nls_date_language=russian') as month
    from  orders o
    where extract(year from o.order_date)=1998 and 
          o.order_status>0
    order by decode(trim(to_char(o.order_date,'month','nls_date_language=russian')),
                '������',1,
                '�������',2,
                '����',3,
                '������',4,
                '���',5,
                '����',6,
                '����',7,
                '������',8,
                '��������',9,
                '�������',10,
                '������',11,
                '�������',12
    ) 
;
/*
 11.�������� ������, ��������� ��� ���� �������� ������. ������� ����� ������ �������
�� sysdate. ������ ������� ������ ��������� ����������� � ���� ������ ���������
��� ������ � �����������. ��� ����������� ��� ������ ��������������� �������
to_char. ��� ������ ����� �� 1 �� 31 ����� ��������������� �������������� rownum,
������� ������ �� ����� �������, ��� ���������� ����� ����� 30.
*/
select   rownum+trunc(sysdate,'mm')-1 as dt,
         case
            when trim(to_char(rownum+trunc(sysdate,'mm')-1,'day','nls_date_language=russian'))='�����������'
                 or trim(to_char(rownum+trunc(sysdate,'mm')-1,'day','nls_date_language=russian'))='�������' then
                    '��������'
            end
        as comments
    from orders o
    where rownum<extract(day from last_day(sysdate))+1
;
/*
 12.������� ���� ����������� (��� ����������, �������+��� ����� ������, ��� ���������,
��������, �������� - %), ������� �������� �������� �� �������. ���������������
������������ is not null.����������� ����������� �� �������� �������� (�� �������� �
��������), ����� �� ���� ����������.
*/
select    e.employee_id,
          e.last_name||' '||e.first_name,
          e.job_id,
          e.salary,
          e.commission_pct
    from  employees e
    where e.commission_pct is not null 
    order by e.commission_pct desc,
             e.employee_id
;
/*
 13.�������� ���������� �� ����� ������ �� 1995-2000 ���� � ������� ��������� (1 �������
� ������-���� � �.�.). � ������� ������ ���� 6 �������� � ���, ����� ������ �� 1-��, 2-
��, 3-�� � 4-�� ��������, � ����� ����� ����� ������ �� ���. ����������� �� ����.
��������������� ������������ �� ����, � ����� ������������� �� ��������� � case
��� decode, ������� ����� �������� ������� �� ������ �������.
*/
select    extract(year from o.order_date) as year,
          sum(
            case 
                when extract(month from o.order_date) between 1 and 3 then
                    o.order_total
                end
          )
          as quartal_1,
          sum(
            case 
                when extract(month from o.order_date) between 4 and 6 then
                    o.order_total
                end
          )
          as quartal_2,
          sum(
            case 
                when extract(month from o.order_date) between 7 and 9 then
                    o.order_total
                end
          )
          as quartal_3,
          sum(
            case 
                when extract(month from o.order_date) between 10 and 12 then
                    o.order_total
                end
          )
          as quartal_4,
          sum(o.order_total) as year_total
    
    from  orders o
    group by extract(year from o.order_date)
    having extract(year from o.order_date) between 1995 and 2000
    order by extract(year from o.order_date)
;

/*
 14.������� �� ������� ������� ��� ����������� ������. ������� ������� ����� �����
��� �������� � �������� ������ ������ � MB ��� GB (� ����� ��������), ��������
������ �� ���������� � HD, � ����� � ������ 30 �������� �������� ������ ��
����������� ����� disk, drive � hard. ������� �������: ��� ������, �������� ������,
��������, ���� (�� ������ � LIST_PRICE), url � ��������. � ���� �������� ������ ����
�������� ����� ����� � ���������� ������� �������� (������, ��� �������� ����� ����
��� � �����). ����������� �� ������� ������ (�� �������� � ��������), ����� �� ����
(�� ������� � �������). ������ ��� �������������� ������� �� �������� ������ ��
������� NN MB/GB (�� ������ ��� ���� ��������������� GB � ���������) c �������
regexp_replace. Like �� ������������, ������ ���� ������������ regexp_like � �����
���������, ��� ������� ���� ������� ������������.
*/
select    p.product_id,
          p.product_name,
          extract(month from p.warranty_period)+extract(year from p.warranty_period)*12 as warranty_months,
          p.list_price,
          p.catalog_url,
          p.warranty_period
    from  product_information p
    where not regexp_like(p.product_name,'^HD\s') 
          and regexp_like(p.product_name,'(.GB|.MB)','i')
          and not regexp_like(substr(p.product_description,1,30),'(disk|drive|hard)','i')
    order by to_number(regexp_substr(regexp_replace(p.product_name,'\d+',
                                                                                        case
                                                                                            when regexp_like(p.product_name,'GB') then
                                                                                                to_char(to_number(regexp_substr(p.product_name,'\d+'))*1024)
                                                                                            else
                                                                                                 to_char(to_number(regexp_substr(p.product_name,'\d+')))
                                                                                            end),'\d+')) desc,
             p.list_price
;            
/*
 15.������� ����� ���������� �����, ���������� �� ��������� �������. ����� ���������
������� � ������� ������ ���� ������ � ���� ������, �������� �21:30�. ������ ��������
������� ���� � ������� ���� �� ������. ����� ��������������� ����������� �������
to_char/to_date.
*/
select   round((to_date(to_char(to_char(sysdate,'dd.mm.yyyy')||' '||'21:05'||':00'),'DD.MM.YYYY HH24:MI:SS')-sysdate)*24*60,0) as minutes
    from dual
;
