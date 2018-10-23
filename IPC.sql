---IPC DEMOS

/*
 
Architektur der Datendateien (Pages, Extents)
Grundsetting des SQL Server  (MAXDOP, MIN und MAX Memory)
Grundsettings bei DB (Intialgrößen und Wachstumsraten, Dateigruppen)
DB Design (logisch und physikalisch)
Messverfahren Teil 1: Statistikmessung, DMVs, Ausführungspläne
TempDB Settings
 
Tag1 nachmittag
Alle Varianten von Indzies mit Übungen
Erläuterungen zu Statistiken

*/


--DB Design


--DB Layout (logisch und physikalisch)
/*Normalisierung ist ok, aber spielt die Physik mit?*/

--Tabellen werden in Seiten und Blöcken untergebracht
--Seite : 8060 bytes Nutzlast (8192)
--1DS muss in Seite passen

--geht nicht.. wg 8060er Grenze
create table txy1 (id int identity, sp1 char(4100), sp2 char(4100));
GO

--geht
create table txyv1 (id int identity, sp1 varchar(4100));
GO

--braucht statt 40MB 80MB ..auch im RAM
insert into txy
select 'XY'
GO 10000

--Wie groß ist diese Tabelle?

select 4100*10000 --40MB

--Messen von "schlechten" Seiten : Durchschn Seitendichte 
dbcc showcontig('txy')

--
set statistics io, time on
--Anzahl der Seiten, CPU Aufwand in ms, Dauer in ms

select * from txy where id = 1000

--ganze Tabelle lesen: SCAN  (von a bis z alles lesen)
dbcc showcontig('txyv')
--achtung: ohne Angabe der Tabelle kann das ewig dauern--> aufwendig!

--DB anlegen

create database ipc

--wieviele Fehler?
--wie groß ist die db jetzt? 5MB 2 MB Log: 7MB
--was wenn Daten reinkommen?
--1GB ...--> Datei vergößern: 1 MB
--Wie groß soll die DB in 2 bis 3 Jahren werden..
--Vergrößerung .. nicht zu groß, aber auch nicht zu klein


--Servereigenschaften
--Daten und Log physikalisch trennen
--Speicher festlegen : OS braucht auch Luft (2GB -- 10%)

--ab  Dollar verwendet der SQL Server mehr CPUs
--wiveiele CPUs: alle
--Default: ab 5 SQL Dollar Kosten alle (0) CPUs

--TEST
--Mit default: 6 Sek CPU und 1,96 Sek Dauer
select country, sum(freight) from customers c 
inner join orders o on c.customerid = o.customerid
group by country

--MIt 4 CPUs: 5,5 Sek CPU und 1,8 Dauer....und 4 freie CPUs
select country, sum(freight) from customers c 
inner join orders o on c.customerid = o.customerid
group by country
option  (maxdop 2) --anzahl der CPUS

--OLTP: 25 /50 SQL Dollar... max 8CPUs 





--TEMPDB: soviele DatenDateien wie Cores, nicht mehr als 8

--Tempdb T1118  T1117


create proc namederprozedur @par1 int, @par2 int
as
--CODE
select @par1*@par2;
GO


exec gpKundenSuche 'A' --alle mit A beginnend

exec gpKundenSuche 'Al' --alle mit Al beginnend

exec gpKundenSuche '%' --alle 

select * from customers where customerid like @par1






--theoretisch richtig
create proc gpkdsearch @kdid char(5)
as
select * from customers where customerid like @kdid +'%'

exec gpkdsearch 'QUICK'

exec gpkdsearch ''

--Proz ist userfriendly


alter proc gpkdsearch @kdid varchar(5)
as
select * from customers where customerid like @kdid +'%'


exec namederprozedur 100,5

1 adhoc 
2 Views
3 Proz
4 F()

-- 2 1 4 3


--SEEK..kein SCAN

--Tabelle Bestellungen angelegt

--CL IX besonders gut bei Bereichsabfragen
--NCL IX gut bei rel wenigen Regebnissen
------> ID... = 

--CL IX wg PK
select * from bestellungen


select * into oxy from orders

select * from oxy

--NIX_Orderid
select orderid, freight from oxy where orderid = 10249




SELECT        Customers.CustomerID, Customers.CompanyName, Customers.ContactName, Customers.City, Customers.Country, Orders.EmployeeID, Orders.OrderDate, Orders.Freight, Orders.ShipCity, Orders.ShipCountry, 
                         [Order Details].OrderID, [Order Details].ProductID, [Order Details].UnitPrice, [Order Details].Quantity, Products.ProductName, Products.UnitsInStock, Employees.LastName, Employees.FirstName, 
                         Employees.BirthDate
INTO Umsatztabelle
FROM            Customers INNER JOIN
                         Orders ON Customers.CustomerID = Orders.CustomerID INNER JOIN
                         Employees ON Orders.EmployeeID = Employees.EmployeeID INNER JOIN
                         [Order Details] ON Orders.OrderID = [Order Details].OrderID INNER JOIN
                         Products ON [Order Details].ProductID = Products.ProductID


insert into umsatztabelle
select * from umsatztabelle


alter table umsatztabelle add ID2 int identity

dbcc showcontig('umsatztabelle') --37547---- 98,32%

--Was steht im Plan
select id from umsatztabelle where ID = 100 --54444

select * from sys.dm_db_index_Physical_Stats(
					db_id(),
					object_id('umsatztabelle'),
					NULL,
					NULL,
					'detailed')

--Brent Ozar: sp_blitz   sp_blitzINdex

sp_blitzindex

select * from umsatztabelle where id = 100

--CL IX SEEK
select * from umsatztabelle
where
	orderdate between '1.1.1997' AND '30.6.1997'


select orderid, city, country from umsatztabelle
where 
		freight = 0.02


select * from sys.dm_db_index_usage_Stats


select companyname, employeeid, lastname 
	from umsatztabelle
	where freight < 1 and country = 'Germany'
GO 3

--Tab A mit 2 MIo Zeilen...> IX 3 Ebenen
------       10 MIO ..200MIO


select * into u3 from umsatztabelle


select top 3 * from u2


select orderid from u2 where productid in (2,3) --28,9 Dollar

--IX?: NIX_prodID

USE [Northwind]

select freight, city from u2 where quantity < 2 and Employeeid = 1

--NIX_QU_EMPL_INKL_fr_ci
--NIX_EMPL_QU_INKL_fr_ci


--Indizes-- NIX = keinen!
--NIX_EMP_QU
--NIX_FR
select country, city from u2 
	where 
	(quantity < 2 and Employeeid = 1) OR freight = 0.02

select top 3 * from u2

--where , AGG, 

select 
country, avg(unitprice)
from u2
where
 orderdate between '1.1.1996' and '1.1.1997' AND UnitsinStock > 10
group by country
GO




select 
country, avg(unitprice)
from u3
where
 orderdate between '1.1.1996' and '1.1.1997' AND UnitsinStock > 10
group by country
GO

CREATE NONCLUSTERED INDEX [NIX_PID] ON [dbo].[u2]
(
	[ProductID] ASC
)
INCLUDE ( 	[OrderID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

GO



    --Was ist besser?
	
--ad-hoc vs Sicht

select * from (select * from customers) as t


create view vdemo1
as
select * from customers

select * from vdemo1

--Sicht ist exakt genauso schnell wie das ad-hoc



create table t1 (id int identity, land int, stadt int)


insert into t1 
select 1,10
union
select 2,20
union 
select 3,30

select * from t1

create view vt1
as
select * from t1

	              
select * from vt1

alter table t1 add region int

update t1 set region = stadt*10

select * from t1



alter table t1 drop column stadt


select * from t1

select * from vt1





alter view dbo.vt1 with schemabinding
as
select id, region from dbo.t1



select country, count(*) from u2 --38995
group by country


1 Trd Zeilen
jdes Land der Welt

200
--indizierte Sichten sind cool.. wenn man Enterprise hat
--errechnete Daten liegen als IX Daten vor

--Kopie der Umsatztabelle
select * into ux from umsatztabelle



select * from ux where id < 2

--Prozeduren sind cool , weil schneller!


select * from ux where id = 10000

select * from customers c inner join orders o 
on c.customerid = o.customerid where orderid =10250



alter procedure gpsucheid @par int
as
select * from ux where id < @par;
GO

select * from ux where id < 1000000 --TSCAN 37523

exec gpsucheid 2--4 ..80

exec gpKundensuche '%'

--der erste Aufruf der Proz entscheidet über den Plan


dbcc freeproccache

alter view dbo.vdemo2 with schemabinding
as
select country, count_BIG(*) as Anzahl from dbo.u2 --38995
group by country


select * from vdemo2



Create procedure gpxy @par int
as
If @par < 20000
proc1 @par
else
proc2 

select * into uy from ux

--SQL Server legt Statistiken über die Verteilung
--der DAten einer Spalte an:
--entweder, wenn ein IX erstellt wird. Dann ist die Stat 100% genau
--oder wenn die Spalte nicht indiziert ist, dann per Stichprobe
--Statistiken können veraltet oder auch falsch sein
----> Falscher Plan

select * from uy where id = 10000 --1

select * from uy where freight= 0.02--4000 ---1024

select * from uy where country = 'UK' and unitsinstock = 10

--Wann werden Statsitiken aktualisiert...
--INS, UP DEL --> mod_counter
--20% +500 + Abfrage mit where aufd die Spalte

--besser wäre im Code verschied. Proc aufzurufen
if 
select * from ux  where id < @par
else
select * from orders where orderid < @par


select * from employees

--wer ist im Rentenalter: 65
--nie f() um Spalte im where

--where datediff


--where sp > f(getdate())



select * from customers where companyname like 'A%'--seek

select * from customers where left(companyname,1) ='A'--scan

--Pauschal: F() sind fast immer Mist!!!

select f() --> Unterabfrage

create function fRNgsumme (@orderid as int)
returns money
as
begin
	return (select sum(unitprice*quantity) from [order details]
			where orderid = @orderid)
end


select dbo.frngsumme (10250)

alter table orders add RngSumme as dbo.Frngsumme(orderid)

select top 10 * from orders where rngsumme > 1000

--Hüte dich vor F()!!


select country, city,count(*) from customers
where 
		city = 'Berlin'
group by 
	country , city
order by 1,2


select country, city,count(*) from customers
--where 
--		city = 'Berlin'
group by 
	country , city having count(*) > 2
order by 1,2


select country, city,count(*) from customers
--where 
--		city = 'Berlin'
group by 
	country , city having city = 'Berlin'
order by 1,2


--Logischer Fluss


select country, city as Stadt,count(*) as Anzahl from customers c
where city = 'Berlin'
group by 
	country , city having count(*) > 2
order by Anzahl



select c. from
--tu nie im having etwas filtern, was ein Where lösen kann!!!

---> FROM --> JOIN --> WHERE --> GRPUP BY  ---> HAVING
----> SELECT (Berechn. Alias) --> ORDER
---> Ausgabe

--Giftliste
While
Dynamisches SQL --sp_executesql
Trigger-- sind langsam aber evtl notwendig
Cursor --

set statistics io, time off
drop table t100
create table t100 (id int identity, sp1 char(4100))

declare @i as int = 1
begin tran
while @i < 10000
	Begin
		insert into t100 values ('xy')
		--Frage
		set @i+=1
	end
commit






A 1
B 1
A 1
A 2



select * into c1 from customers where country like 'U%'





--distinct
select * from customers --90
union ALL
select * from c1 --20
--kein UNION , wenn keine doppelten!.....
--sondern UNION ALL

--Profiler
--Optimierungsassistent


