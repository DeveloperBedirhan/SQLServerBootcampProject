USE northwind
SELECT CategoryId,CategoryName FROM Categories WHERE CategoryID >= 3 AND CategoryName='Produce'
SELECT * FROM Categories WHERE CategoryID > 3 AND CategoryID < 5

-- 1. Tanım Sorusu: Northwind veritabanında toplam kaç tablo vardır? Bu tabloların isimlerini listeleyiniz.
SELECT COUNT(*) AS TableCount FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';


-- 2. JOIN Sorusu: Her sipariş (Orders) için, Şirket adı (CompanyName), çalışan adı (Employee Full Name), sipariş tarihi ve 
-- gönderici şirketin adı (Shipper) ile birlikte bir liste çıkarın.
SELECT ord.OrderID,ord.CustomerID,cus.CompanyName,emp.FirstName+''+emp.LastName as 'Employee Full Name',ord.OrderDate,shi.CompanyName
FROM Orders ord,Customers cus,Employees emp,Shippers shi 
WHERE ord.CustomerID=cus.CustomerID AND ord.EmployeeID=emp.EmployeeID AND ord.ShipVia=shi.ShipperID


-- 3. Aggregate Fonksiyon: Tüm siparişlerin toplam tutarını bulun. (Order Details tablosundaki Quantity UnitPrice üzerinden hesaplayınız.
SELECT orddet.OrderID,SUM(orddet.UnitPrice*orddet.Quantity) as [Toplam Tutar]
FROM [Order Details] as orddet
GROUP BY orddet.OrderID

SELECT SUM(orddet.UnitPrice*orddet.Quantity) as [Genel Toplam] FROM [Order Details] as orddet


-- 4. Gruplama: Hangi ülkeden kaç müşteri vardır?
SELECT cus.Country,COUNT(cus.Country) as[Toplam Müşteri Sayısı] FROM Customers cus GROUP BY cus.Country


-- 5. Subquery Kullanımı: En pahalı ürünün adını ve fiyatını listeleyiniz.
SELECT TOP 1 ProductName,UnitPrice FROM Products ORDER BY UnitPrice DESC

-- 6. JOIN ve Aggregate: Çalışan başına düşen sipariş sayısını gösteren bir liste çıkarınız.
SELECT ord.EmployeeID,emp.FirstName+''+emp.LastName as [Çalışan Adı],COUNT(ord.EmployeeID) as [Toplam Sipariş Sayısı] 
FROM Orders ord JOIN Employees emp ON ord.EmployeeID=emp.EmployeeID GROUP BY ord.EmployeeID, emp.FirstName, emp.LastName;


-- 7. Tarih Filtreleme: 1997 yılında verilen siparişleri listeleyin.
SELECT ord.OrderID,ord.OrderDate FROM Orders ord WHERE ord.OrderDate LIKE '%1997%'

-- 8. CASE Kullanımı: Ürünleri fiyat aralıklarına göre kategorilere ayırarak listeleyin: 020 → Ucuz, 2050 → Orta, 50+ → Pahalı.
SELECT pro.ProductID,pro.ProductName,pro.UnitPrice,
	CASE
		WHEN pro.UnitPrice<20 THEN 'Ucuz'
		WHEN pro.UnitPrice BETWEEN 20 AND 50 THEN 'Orta'
		WHEN pro.UnitPrice>50 THEN 'Pahalı'
	END AS [Fiyat Aralığı]
FROM Products pro

-- 9. Nested Subquery: En çok sipariş verilen ürünün adını ve sipariş adedini (adet bazında) bulun.
SELECT TOP 1 pro.ProductName, COUNT(ordDet.ProductID) AS [Sipariş Adedi]
FROM [Order Details] ordDet
JOIN Products pro ON ordDet.ProductID = pro.ProductID
GROUP BY pro.ProductName
ORDER BY [Sipariş Adedi] DESC;


-- 10. View Oluşturma: Ürünler ve kategoriler bilgilerini birleştiren bir görünüm (view) oluşturun.
CREATE VIEW vw_ProductsWithCategories AS
SELECT P.ProductID,P.ProductName,P.UnitPrice,P.QuantityPerUnit,C.CategoryID,C.CategoryName,C.Description AS CategoryDescription
FROM Products P JOIN Categories C ON P.CategoryID = C.CategoryID;

SELECT * FROM vw_ProductsWithCategories;

-- 11. Trigger: Ürün silindiğinde log tablosuna kayıt yapan bir trigger yazınız.
CREATE TABLE ProductLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    ProductName NVARCHAR(50),
    DeletedAt DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_ProductDeleteLog ON Products
AFTER DELETE AS BEGIN
    INSERT INTO ProductLog (ProductID, ProductName, DeletedAt)
    SELECT deleted.ProductID, deleted.ProductName, GETDATE() FROM deleted;
END;

ALTER TABLE [Order Details] DROP CONSTRAINT FK_Order_Details_Products;

ALTER TABLE [Order Details] 
ADD CONSTRAINT FK_Order_Details_Products 
FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE;

DELETE FROM Products WHERE ProductID = 77;
SELECT * FROM ProductLog;

-- 12. Stored Procedure: Belirli bir ülkeye ait müşterileri listeleyen bir stored procedure yazınız.
CREATE PROCEDURE GetCustomersByCountry @Country NVARCHAR(25)
AS BEGIN
    SELECT CustomerID,CompanyName,ContactName,City,Country FROM Customers WHERE Country = @Country;
END;

EXEC GetCustomersByCountry @Country = 'Germany';

-- 13. Left Join Kullanımı: Tüm ürünlerin tedarikçileriyle (suppliers) birlikte listesini yapın. Tedarikçisi olmayan ürünler de listelensin.
SELECT pro.ProductID,pro.ProductName,pro.SupplierID,sup.CompanyName FROM Products pro LEFT JOIN Suppliers sup ON pro.SupplierID=sup.SupplierID

-- 14. Fiyat Ortalamasının Üzerindeki Ürünler: Fiyatı ortalama fiyatın üzerinde olan ürünleri listeleyin.
SELECT ProductID, ProductName, UnitPrice FROM Products WHERE UnitPrice > (SELECT AVG(UnitPrice) FROM Products);


-- 15. En Çok Ürün Satan Çalışan: Sipariş detaylarına göre en çok ürün satan çalışan kimdir?
SELECT TOP 1 E.EmployeeID,E.FirstName + ' ' + E.LastName AS EmployeeName,SUM(OD.Quantity) AS TotalProductsSold
FROM Employees E
JOIN Orders O ON E.EmployeeID = O.EmployeeID
JOIN [Order Details] OD ON O.OrderID = OD.OrderID
GROUP BY E.EmployeeID, E.FirstName, E.LastName
ORDER BY TotalProductsSold DESC


SELECT ordDet.OrderID,COUNT(ordDet.OrderID)*ordDet.Quantity,emp.EmployeeID,COUNT(ord.EmployeeID) as[Satış Miktarı]
FROM Orders ord 
JOIN  Employees emp  ON ord.EmployeeID = emp.EmployeeID 
JOIN [Order Details] ordDet ON ord.OrderID=ordDet.OrderID 
GROUP BY ord.EmployeeID,emp.EmployeeID,ordDet.OrderID,ordDet.Quantity
--??

-- 16. Ürün Stoğu Kontrolü: Stok miktarı 10’un altında olan ürünleri listeleyiniz.
SELECT ProductID,ProductName,UnitsInStock FROM Products WHERE UnitsInStock<10

-- 17. Şirketlere Göre Sipariş Sayısı: Her müşteri şirketinin yaptığı sipariş sayısını ve toplam harcamasını bulun.
SELECT C.CustomerID,C.CompanyName, COUNT(O.OrderID) AS [Toplam Sipariş], SUM(OD.UnitPrice * OD.Quantity) AS [Toplam Harcama]
FROM Customers C
JOIN Orders O ON C.CustomerID = O.CustomerID
JOIN [Order Details] OD ON O.OrderID = OD.OrderID
GROUP BY C.CustomerID,C.CompanyName

-- 18. En Fazla Müşterisi Olan Ülke: Hangi ülkede en fazla müşteri var?
SELECT TOP 1 Country,COUNT(Country) as MostCustomers FROM Customers GROUP BY Country ORDER BY Country DESC

-- 19. Her Siparişteki Ürün Sayısı: Siparişlerde kaç farklı ürün olduğu bilgisini listeleyin.
SELECT OrderID,COUNT(DISTINCT ProductID) AS ProductCount FROM [Order Details] GROUP BY OrderID


-- 20. Ürün Kategorilerine Göre Ortalama Fiyat: Her kategoriye göre ortalama ürün fiyatını bulun.
SELECT CategoryID,COUNT(CategoryID) AS TotalCategory,AVG(UnitPrice) AS AveragePrice FROM Products GROUP BY CategoryID

-- 21. Aylık Sipariş Sayısı: Siparişleri ay ay gruplayarak kaç sipariş olduğunu listeleyin.
SELECT 
    FORMAT(OrderDate, 'yyyy-MM') AS OrderMonth, 
    COUNT(OrderID) AS OrderCount
FROM Orders
GROUP BY FORMAT(OrderDate, 'yyyy-MM')
ORDER BY OrderMonth;


-- 22. Çalışanların Müşteri Sayısı: Her çalışanın ilgilendiği müşteri sayısını listeleyin.
SELECT 
    E.EmployeeID,
    E.FirstName + ' ' + E.LastName AS EmployeeName,
    COUNT(DISTINCT O.CustomerID) AS CustomerCount
FROM Employees E
JOIN Orders O ON E.EmployeeID = O.EmployeeID
GROUP BY E.EmployeeID, E.FirstName, E.LastName


-- 23. Hiç siparişi olmayan müşterileri listeleyin.
SELECT C.CustomerID, C.CompanyName
FROM Customers C
LEFT JOIN Orders O ON C.CustomerID = O.CustomerID
WHERE O.OrderID IS NULL;


-- 24. Siparişlerin Nakliye (Freight) Maliyeti Analizi: Nakliye maliyetine göre en pahalı 5 siparişi listeleyin.
SELECT TOP 5 OrderID,Freight FROM Orders GROUP BY OrderID,Freight ORDER BY Freight DESC
