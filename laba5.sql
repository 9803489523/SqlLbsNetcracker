--специальности (группы)
create table groups(
    group_id int primary key,
    group_name varchar(100) not null unique
);

--предметы
create table subjects(
  subject_id int primary key,
  subject_name varchar(100) not null unique
);

--учебный план
create table learning_plan(
  lp_id int primary key,
  group_id int not null,
  semester int not null,
  subject_id int not null,
  reporting_type varchar(3) not null,
  foreign key(group_id) references groups(group_id),
  foreign key(subject_id) references subjects(subject_id),
  check (reporting_type in ('ZA','ZAO','EX'))
);

--студенты
create table students(
  student_id int primary key,
  fio varchar(200) not null,
  group_id int not null,
  receipt_date date not null,
  foreign key(group_id) references groups(group_id)
);

--оценки
create table marks(
  mark_id int primary key,
  mark_number int,
  mark_date date not null,
  student_id int not null,
  lp_id int not null,
  foreign key(student_id) references students(student_id),
  foreign key(lp_id) references  learning_plan(lp_id)
);

--тригеры

--для инкрементации специальностей
create sequence group_seq
  minvalue 1
  maxvalue 9999999999999999999999999999
  increment by 1
  nocache noorder nocycle
;

create trigger groups_tr_set_id
  before insert on groups
  for each row
begin
  if :new.group_id is null then
    select group_seq.nextval
      into :new.group_id 
      from dual;
  end if;
end;

alter trigger groups_tr_set_id enable;

--для инкрементации предметов
create sequence subject_seq
  minvalue 1
  maxvalue 9999999999999999999999999999
  increment by 1
  nocache noorder nocycle
;

create trigger subjects_tr_set_id
  before insert on subjects
  for each row
begin
  if :new.subject_id is null then
    select subject_seq.nextval
      into :new.subject_id 
      from dual;
  end if;
end;

alter trigger subjects_tr_set_id enable;

--для инкрементации учебного плана
create sequence lp_seq
  minvalue 1
  maxvalue 9999999999999999999999999999
  increment by 1
  nocache noorder nocycle
;

create trigger lp_tr_set_id
  before insert on learning_plan
  for each row
begin
  if :new.lp_id is null then
    select lp_seq.nextval
      into :new.lp_id 
      from dual;
  end if;
end;

alter trigger lp_tr_set_id enable;

--для инкрементации студентов
create sequence student_seq
  minvalue 1
  maxvalue 9999999999999999999999999999
  increment by 1
  nocache noorder nocycle
;

create trigger students_tr_set_id
  before insert on students
  for each row
begin
  if :new.student_id is null then
    select student_seq.nextval
      into :new.student_id 
      from dual;
  end if;
end;

alter trigger students_tr_set_id enable;

--для инкрементации оценок
create sequence mark_seq
  minvalue 1
  maxvalue 9999999999999999999999999999
  increment by 1
  nocache noorder nocycle
;

create trigger marks_tr_set_id
  before insert on marks
  for each row
begin
  if :new.mark_id is null then
    select mark_seq.nextval
      into :new.mark_id 
      from dual;
  end if;
end;

alter trigger marks_tr_set_id enable;

--вставка данных
insert all
  into groups (group_name) values ('информатика и вычислительная техника')
  into groups (group_name) values ('информационная безопасность')
  into groups (group_name) values ('информационные системы и технологии')
select * from dual
;

select *
  from groups;

insert all
  into subjects (subject_name) values ('компьютерные сети')
  into subjects (subject_name) values ('базы данных')
  into subjects (subject_name) values ('объектно-ориентированное программирование')
  into subjects (subject_name) values ('технологии и метоы программирования')
  into subjects (subject_name) values ('физическая культура')
  into subjects (subject_name) values ('физика')
  into subjects (subject_name) values ('дискретная математика')
select * from dual
;

select * 
  from subjects;
  
insert all
  into students(fio,group_id,receipt_date) values ('Денис Баранов',1,date'2018-01-04')
  into students(fio,group_id,receipt_date) values ('Дмитрий Бабянин',1,date'2019-01-04')
  into students(fio,group_id,receipt_date) values ('Алексей Попов',1,date'2019-01-04')
  into students(fio,group_id,receipt_date) values ('Михаил Кретов',2,date'2019-01-04')
  into students(fio,group_id,receipt_date) values ('Анна Ушакова',2,date'2018-01-04')
  into students(fio,group_id,receipt_date) values ('Дарья Мясникова',2,date'2018-01-04')
  into students(fio,group_id,receipt_date) values ('Дмитрий Червячный',3,date'2018-01-04')
  into students(fio,group_id,receipt_date) values ('Махмуд Бабаджан',3,date'2018-01-04')
  into students(fio,group_id,receipt_date) values ('Георгий Елизаров',3,date'2019-01-04')
select * from dual;

select *
  from students;

insert all
  into learning_plan(group_id,semester,subject_id,reporting_type) values (1,1,38,'ZAO')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (1,1,39,'EX')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (1,1,40,'EX')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (1,1,41,'EX')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (1,1,42,'EX')
  
  into learning_plan(group_id,semester,subject_id,reporting_type) values (2,4,42,'ZAO')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (2,4,38,'EX')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (2,4,39,'EX')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (2,4,43,'EX')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (2,4,44,'ZAO')
  
  into learning_plan(group_id,semester,subject_id,reporting_type) values (3,3,42,'ZAO')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (3,3,38,'EX')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (3,3,39,'ZAO')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (3,3,44,'ZAO')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (3,3,43,'EX')
  
  
  into learning_plan(group_id,semester,subject_id,reporting_type) values (1,5,38,'ZAO')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (1,5,39,'ZAO')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (1,5,40,'ZAO')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (1,5,41,'EX')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (1,5,42,'EX')
  
  into learning_plan(group_id,semester,subject_id,reporting_type) values (2,2,39,'ZAO')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (2,2,40,'EX')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (2,2,41,'ZAO')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (2,2,42,'ZA')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (2,2,43,'ZAO')
  
  into learning_plan(group_id,semester,subject_id,reporting_type) values (3,4,39,'ZAO')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (3,4,40,'EX')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (3,4,41,'ZAO')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (3,4,42,'ZAO')
  into learning_plan(group_id,semester,subject_id,reporting_type) values (3,4,38,'EX')
  
select * from dual
;

select *
  from learning_plan;

insert all
  into marks(mark_number,mark_date,student_id,lp_id) values (5,date'2019-02-04',19,91)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2019-02-05'	,	19	,	92	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2019-02-06'	,	19	,	93	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2019-02-07'	,	19	,	94	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	null	,date'2019-02-08'	,	19	,	95	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	5	,date'2019-02-05'	,	20	,	92	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	4	,date'2019-02-06'	,	20	,	93	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	3	,date'2019-02-07'	,	20	,	94	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	4	,date'2019-02-08'	,	20	,	95	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	4	,date'2019-02-04'	,	20	,	91	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2019-02-05'	,	21	,	92	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2019-02-06'	,	21	,	93	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2019-02-07'	,	21	,	94	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2019-02-08'	,	21	,	95	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2019-02-04'	,	21	,	91	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2020-02-05'	,	22	,	96	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2020-02-06'	,	22	,	97	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2020-02-07'	,	22	,	98	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2020-02-08'	,	22	,	99	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2020-02-04'	,	22	,	100	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	3	,date'2020-02-05'	,	23	,	96	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	5	,date'2020-02-06'	,	23	,	97	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	4	,date'2020-02-07'	,	23	,	98	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	4	,date'2020-02-08'	,	23	,	99	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	5	,date'2020-02-04'	,	23	,	100	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	5	,date'2020-02-05'	,	24	,	96	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	5	,date'2020-02-06'	,	24	,	97	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	4	,date'2020-02-07'	,	24	,	98	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	5	,date'2020-02-08'	,	24	,	99	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	5	,date'2020-02-04'	,	24	,	100	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	5	,date'2021-02-05'	,	25	,	101	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	5	,date'2021-02-06'	,	25	,	102	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	4	,date'2021-02-07'	,	25	,	103	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	5	,date'2021-02-08'	,	25	,	104	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	5	,date'2021-02-04'	,	25	,	105	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2021-02-05'	,	26	,	101	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2021-02-06'	,	26	,	102	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2021-02-07'	,	26	,	103	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	4	,date'2021-02-08'	,	26	,	104	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2021-02-04'	,	26	,	105	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	4	,date'2021-02-05'	,	27	,	101	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	5	,date'2021-02-06'	,	27	,	102	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	3	,date'2021-02-07'	,	27	,	103	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	4	,date'2021-02-08'	,	27	,	104	)
  into marks(mark_number,mark_date,student_id,lp_id) values (	2	,date'2021-02-04'	,	27	,	105	)
select * from dual
;

select *
  from marks;
  
--функции
create or replace function fn_count_semester (
  p_student_id in students.student_id%type
) return number
is
  v_student_date students.receipt_date%type;
begin
  select s.receipt_date
    into v_student_date
    from students s
    where s.student_id = p_student_id;
  return round(((sysdate-v_student_date)/180),0)-1;
end;

create or replace function fn_get_course(
  p_student_id in students.student_id%type
) return number
is
  v_student_date students.receipt_date%type;
begin
  select s.receipt_date
    into v_student_date
    from students s
    where s.student_id = p_student_id;
  return round((round(((sysdate-v_student_date)/180),0)-1)/2,0);
end;

--запросы
create or replace view students_with_tails as
select s.fio as "студент",
       fn_get_course(s.student_id) as "курс",
       sub.subject_id as "код предмета",
       sub.subject_name as "название предмета",
       fn_count_semester(s.student_id) as "текущий семестр",
       m.mark_number as "оценка"    
  from marks m
    inner join learning_plan lp
      on lp.lp_id=m.lp_id
    inner join students s
      on s.student_id=m.student_id
    inner join subjects sub
      on sub.subject_id=lp.subject_id
  where m.mark_number=2
  order by s.fio
;  
  
select stv.fio,
       count(*) as "количество долгов"
  from students_with_tails stv
  group by stv.fio
  having  count(*)>=4
  order by count(*)
;
