CREATE DATABASE  onlinewarehouse;
USE onlinewarehouse;

-- Create tables
-- Table for suppliers
CREATE TABLE SupplierInfo (
    SupplierID INT AUTO_INCREMENT PRIMARY KEY,
    SupplierName VARCHAR(100) NOT NULL,
    ContactInfo VARCHAR(255)
);

-- Table for products
CREATE TABLE Products (
    ProductID INT AUTO_INCREMENT PRIMARY KEY,
    ProductName VARCHAR(255) NOT NULL,
    Category VARCHAR(100),
    Description TEXT
);

-- Table for product-supplier relationships with pricing
CREATE TABLE ProductSuppliers (
    ProductSupplierID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT NOT NULL,
    SupplierID INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    FOREIGN KEY (SupplierID) REFERENCES SupplierInfo(SupplierID)
);

-- Table for customers
CREATE TABLE CustomerInfo (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100) UNIQUE,
    IsMember BOOLEAN NOT NULL DEFAULT FALSE
);

-- Table for customer orders
CREATE TABLE CustomerOrders (
    OrderID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    Status ENUM('Complete', 'Incomplete') DEFAULT 'Incomplete',
    TotalAmount DECIMAL(10, 2),
    FOREIGN KEY (CustomerID) REFERENCES CustomerInfo(CustomerID)
);

-- Table for order details
CREATE TABLE OrderDetails (
    OrderDetailID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductSupplierID INT NOT NULL,
    Quantity INT NOT NULL,
    SubTotal DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES CustomerOrders(OrderID),
    FOREIGN KEY (ProductSupplierID) REFERENCES ProductSuppliers(ProductSupplierID)
);

-- Table for customer feedback (reviews and time spent)
CREATE TABLE CustomerReviews (
    ReviewID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT NOT NULL,
    ProductID INT NOT NULL,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    Review TEXT,
    TimeSpentMinutes INT NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES CustomerInfo(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- Table for extra costs
CREATE TABLE AdditionalCosts (
    CostID INT AUTO_INCREMENT PRIMARY KEY,
    Type ENUM('Delivery Failure', 'Re-Attempt', 'Return Fraud'),
    Amount DECIMAL(10, 2) NOT NULL,
    OrderID INT,
    FOREIGN KEY (OrderID) REFERENCES CustomerOrders(OrderID)
);

-- Table for commissions
CREATE TABLE SupplierCommissions (
    CommissionID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    SupplierID INT NOT NULL,
    CommissionRate DECIMAL(5, 2) NOT NULL,
    TotalCommission DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES CustomerOrders(OrderID),
    FOREIGN KEY (SupplierID) REFERENCES SupplierInfo(SupplierID)
);

DELIMITER //

CREATE TRIGGER BeforeInsertCustomerReview
BEFORE INSERT ON CustomerReviews
FOR EACH ROW
BEGIN
    -- Ensure the rating is between 1 and 5
    IF NEW.Rating < 1 OR NEW.Rating > 5 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Rating: Rating must be between 1 and 5.';
    END IF;

    -- Ensure the TimeSpentMinutes is positive
    IF NEW.TimeSpentMinutes <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid TimeSpentMinutes: Must be greater than 0.';
    END IF;

    -- Ensure CustomerID exists in CustomerInfo table
    IF NOT EXISTS (SELECT 1 FROM CustomerInfo WHERE CustomerID = NEW.CustomerID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid CustomerID: Customer does not exist.';
    END IF;

    -- Ensure ProductID exists in Products table
    IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = NEW.ProductID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid ProductID: Product does not exist.';
    END IF;
END;
//

DELIMITER ;

-- Insert 100 suppliers into the SupplierInfo table
INSERT INTO SupplierInfo (SupplierName, ContactInfo)
SELECT 
    CONCAT('Supplier ', id) AS SupplierName,
    CONCAT('contact', id, '@supplier.com') AS ContactInfo
FROM 
    (SELECT @rownum := @rownum + 1 AS id FROM INFORMATION_SCHEMA.COLUMNS, (SELECT @rownum := 0) AS Init LIMIT 100) AS Temp;

-- Insert 1000 products into the Products table
INSERT INTO Products (ProductName, Category, Description)
SELECT 
    CONCAT('Product ', id) AS ProductName,
    CONCAT('Category ', FLOOR(RAND() * 10) + 1) AS Category,
    CONCAT('Description for Product ', id) AS Description
FROM 
    (SELECT @rownum := @rownum + 1 AS id FROM INFORMATION_SCHEMA.COLUMNS, (SELECT @rownum := 0) AS Init LIMIT 1000) AS Temp;

-- Insert product-supplier relationships with pricing into the ProductSuppliers table
INSERT INTO ProductSuppliers (ProductID, SupplierID, Price)
SELECT 
    FLOOR(RAND() * 1000) + 1 AS ProductID,
    FLOOR(RAND() * 100) + 1 AS SupplierID,
    ROUND(RAND() * 500, 2) AS Price
FROM 
    (SELECT @rownum := @rownum + 1 AS id FROM INFORMATION_SCHEMA.COLUMNS, (SELECT @rownum := 0) AS Init LIMIT 1000) AS Temp;

-- Insert 1000 customers into the CustomerInfo table
INSERT INTO CustomerInfo (Name, Email, IsMember)
SELECT 
    CONCAT('Customer ', id) AS Name,
    CONCAT('customer', id, '@example.com') AS Email,
    FLOOR(RAND() * 2) AS IsMember
FROM 
    (SELECT @rownum := @rownum + 1 AS id FROM INFORMATION_SCHEMA.COLUMNS, (SELECT @rownum := 0) AS Init LIMIT 1000) AS Temp;

-- Insert 10,000 orders into the CustomerOrders table
INSERT INTO CustomerOrders (CustomerID, OrderDate, Status, TotalAmount)
SELECT 
    CustomerID,
    NOW() - INTERVAL FLOOR(RAND() * 365) DAY AS OrderDate,
    IF(FLOOR(RAND() * 2) = 0, 'Complete', 'Incomplete') AS Status,
    ROUND(RAND() * 100, 2) AS TotalAmount
FROM 
    (SELECT CustomerID FROM CustomerInfo LIMIT 100) AS ValidCustomers
CROSS JOIN 
    (SELECT @rownum := @rownum + 1 AS id FROM INFORMATION_SCHEMA.COLUMNS, (SELECT @rownum := 0) AS Init LIMIT 10000) AS Temp;

-- Insert random order details into the OrderDetails table
INSERT INTO OrderDetails (OrderID, ProductSupplierID, Quantity, SubTotal)
SELECT 
    OrderID,
    FLOOR(RAND() * (SELECT COUNT(*) FROM ProductSuppliers)) + 1 AS ProductSupplierID,
    FLOOR(RAND() * 10) + 1 AS Quantity,
    ROUND(RAND() * 100, 2) AS SubTotal
FROM 
    CustomerOrders
LIMIT 100;

-- Insert random customer feedback (reviews) into the CustomerReviews table
INSERT INTO CustomerReviews (CustomerID, ProductID, Rating, Review, TimeSpentMinutes)
SELECT 
    CustomerID,
    FLOOR(RAND() * 100) + 1 AS ProductID,
    FLOOR(RAND() * 5) + 1 AS Rating,
    CONCAT('Review for Product ', FLOOR(RAND() * 100) + 1) AS Review,
    FLOOR(RAND() * 60) + 1 AS TimeSpentMinutes
FROM 
    CustomerInfo
CROSS JOIN 
    (SELECT @rownum := @rownum + 1 AS id FROM INFORMATION_SCHEMA.COLUMNS, (SELECT @rownum := 0) AS Init LIMIT 100) AS Temp;

-- Insert 100 random extra costs at a time
INSERT INTO AdditionalCosts (Type, Amount, OrderID)
SELECT 
    CASE 
        WHEN FLOOR(RAND() * 3) = 0 THEN 'Delivery Failure'
        WHEN FLOOR(RAND() * 2) = 0 THEN 'Re-Attempt'
        ELSE 'Return Fraud'
    END AS Type,
    ROUND(RAND() * 100, 2) AS Amount,
    OrderID
FROM 
    CustomerOrders
LIMIT 100;

-- Insert 100 rows into SupplierCommissions at a time
INSERT INTO SupplierCommissions (OrderID, SupplierID, CommissionRate, TotalCommission)
SELECT 
    OrderID,
    (SELECT SupplierID FROM SupplierInfo ORDER BY RAND() LIMIT 1) AS SupplierID,
    ROUND(RAND() * 10, 2) AS CommissionRate,
    ROUND(RAND() * 1000, 2) AS TotalCommission
FROM 
    CustomerOrders
LIMIT 100;


-- Objective 1: Analyze the current supply chain performance of the company

-- Query 1: Identify the total sales for each supplier and product
SELECT si.SupplierName, p.ProductName, SUM(od.Quantity * ps.Price) AS TotalSales
FROM SupplierInfo si
INNER JOIN ProductSuppliers ps ON si.SupplierID = ps.SupplierID
INNER JOIN Products p ON ps.ProductID = p.ProductID
INNER JOIN OrderDetails od ON ps.ProductSupplierID = od.ProductSupplierID
INNER JOIN CustomerOrders co ON od.OrderID = co.OrderID
WHERE co.Status = 'Complete'
GROUP BY si.SupplierName, p.ProductName;


-- Query 2: Find the products with the highest sales by category
SELECT p.Category, p.ProductName, MAX(od.Quantity * ps.Price) AS MaxSales
FROM Products p
INNER JOIN ProductSuppliers ps ON p.ProductID = ps.ProductID
INNER JOIN OrderDetails od ON ps.ProductSupplierID = od.ProductSupplierID
INNER JOIN CustomerOrders co ON od.OrderID = co.OrderID
WHERE co.Status = 'Complete'
GROUP BY p.Category, p.ProductName
ORDER BY MaxSales DESC;

-- Count the number of products supplied by each supplier
SELECT si.SupplierName, COUNT(DISTINCT ps.ProductID) AS ProductCount
FROM SupplierInfo si
INNER JOIN ProductSuppliers ps ON si.SupplierID = ps.SupplierID
GROUP BY si.SupplierName;

-- Objective 3: Enhance customer satisfaction and optimize operational costs

-- Query 4: Identify customers who have provided feedback on the most products
SELECT ci.Name, COUNT(DISTINCT cr.ProductID) AS ProductsReviewed
FROM CustomerInfo ci
LEFT JOIN CustomerReviews cr ON ci.CustomerID = cr.CustomerID
GROUP BY ci.Name
ORDER BY ProductsReviewed DESC;

-- Query 5: List all the products with more than 5 reviews and average rating
SELECT p.ProductName, COUNT(r.ReviewID) AS ReviewCount, AVG(r.Rating) AS AvgRating
FROM Products p
INNER JOIN CustomerReviews r ON p.ProductID = r.ProductID
GROUP BY p.ProductName
HAVING COUNT(r.ReviewID) > 5
ORDER BY AvgRating DESC;

-- Query 6: Calculate the total cost of failed delivery incidents
SELECT 'Delivery Failure' AS CostType, SUM(ac.Amount) AS TotalCost
FROM AdditionalCosts ac
WHERE ac.Type = 'Delivery Failure'
UNION
SELECT 'Re-Attempt' AS CostType, SUM(ac.Amount) AS TotalCost
FROM AdditionalCosts ac
WHERE ac.Type = 'Re-Attempt';

-- Query 7: List suppliers with total commissions in the last 30 days
SELECT si.SupplierName, SUM(sc.TotalCommission) OVER (PARTITION BY si.SupplierID) AS TotalCommissions
FROM SupplierInfo si
INNER JOIN SupplierCommissions sc ON si.SupplierID = sc.SupplierID
INNER JOIN CustomerOrders co ON sc.OrderID = co.OrderID
WHERE co.OrderDate >= CURDATE() - INTERVAL 30 DAY
ORDER BY TotalCommissions DESC;


DELIMITER $$

CREATE PROCEDURE monthly_report(IN report_month VARCHAR(7))
BEGIN
    -- Declare variables to store revenue and costs
    DECLARE total_revenue DECIMAL(10, 2);
    DECLARE total_extra_costs DECIMAL(10, 2);
    DECLARE total_commissions DECIMAL(10, 2);
    DECLARE total_profit DECIMAL(10, 2);
    
    -- Calculate total revenue
    SELECT 
        SUM(od.Quantity * ps.Price) 
    INTO total_revenue
    FROM CustomerOrders co
    JOIN OrderDetails od ON co.OrderID = od.OrderID
    JOIN ProductSuppliers ps ON od.ProductSupplierID = ps.ProductSupplierID
    WHERE co.Status = 'Complete'
    AND DATE_FORMAT(co.OrderDate, '%Y-%m') = report_month;
    
    -- Calculate total extra costs and total commissions
    SELECT 
        IFNULL(SUM(ac.Amount), 0) + IFNULL(SUM(sc.TotalCommission), 0)
    INTO total_extra_costs
    FROM CustomerOrders co
    LEFT JOIN AdditionalCosts ac ON co.OrderID = ac.OrderID
    LEFT JOIN SupplierCommissions sc ON co.OrderID = sc.OrderID
    WHERE DATE_FORMAT(co.OrderDate, '%Y-%m') = report_month;
    
    -- Calculate total profit
    SET total_profit = total_revenue - total_extra_costs;
    
    -- Output the results
    SELECT 
        total_revenue AS Revenue,
        total_extra_costs AS Costs,
        total_profit AS Profit;
END $$

DELIMITER ;

CALL monthly_report('2024-12');
