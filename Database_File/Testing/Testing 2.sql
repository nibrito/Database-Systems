-- ==========================================
-- SECTION 5: ADVANCED TRIGGER TESTS
-- ==========================================

-- ------------------------------------------
-- 5.1 Test Automatic Inventory Deduction on Order Placement
-- Scenario: When an item is ordered, inventory levels for its 
-- underlying ingredients should automatically decrease.
-- ------------------------------------------

-- Step A: Note current ingredient stock level before ordering
SELECT inv.branch_id, inv.ingredient_id, i.ingredient_name, inv.quantity_in_stock
FROM Inventory inv
JOIN Ingredient i ON inv.ingredient_id = i.ingredient_id
WHERE inv.branch_id = 1 AND inv.ingredient_id = 5;

-- Step B: Insert a new order item
INSERT INTO OrderItem (order_id, food_id, quantity, unit_price)
VALUES (1, 3, 2, 250.00);

-- Step C: Verify ingredient stock has decreased accordingly
SELECT inv.branch_id, inv.ingredient_id, i.ingredient_name, inv.quantity_in_stock
FROM Inventory inv
JOIN Ingredient i ON inv.ingredient_id = i.ingredient_id
WHERE inv.branch_id = 1 AND inv.ingredient_id = 5;


-- ------------------------------------------
-- 5.2 Test Order Line-Item Deletion (`OrderItem_OnDelete`)
-- Scenario: Deleting an OrderItem should reduce Orders.total_amount 
-- and restore ingredient inventory levels.
-- ------------------------------------------

-- Step A: Check current order total and inventory stock
SELECT order_id, total_amount FROM Orders WHERE order_id = 1;
SELECT ingredient_id, quantity_in_stock FROM Inventory WHERE branch_id = 1 AND ingredient_id = 5;

-- Step B: Remove an item from the order
DELETE FROM OrderItem 
WHERE order_id = 1 AND food_id = 3 
LIMIT 1;

-- Step C: Verify order total decreased and inventory restored
SELECT order_id, total_amount FROM Orders WHERE order_id = 1;
SELECT ingredient_id, quantity_in_stock FROM Inventory WHERE branch_id = 1 AND ingredient_id = 5;


-- ------------------------------------------
-- 5.3 Test Food Price Update Synchronization
-- Scenario: Changing a food item's price in `Food` table should update 
-- or log updates without breaking existing completed order historical data.
-- ------------------------------------------

-- Step A: Check current menu price
SELECT food_id, food_name, price FROM Food WHERE food_id = 2;

-- Step B: Update base price of the item
UPDATE Food
SET price = 450.00
WHERE food_id = 2;

-- Step C: Confirm base price updated while past order unit prices remain untouched
SELECT food_id, food_name, price FROM Food WHERE food_id = 2;
SELECT order_id, food_id, unit_price FROM OrderItem WHERE food_id = 2;


-- ------------------------------------------
-- 5.4 Test Prevent Negative Inventory Stock (`Check_Stock_Level`)
-- Scenario: Trigger raises an error/prevents transaction if order quantity 
-- exceeds available stock.
-- ------------------------------------------

-- Attempt to insert an order item with unrealistically large quantity
-- Expected Result: Query fails with stock violation error
INSERT INTO OrderItem (order_id, food_id, quantity, unit_price)
VALUES (1, 1, 99999, 500.00);


-- ------------------------------------------
-- 5.5 Test Updated At Timestamp Auto-Refresh
-- Scenario: Updating customer details should automatically touch the `updated_at` column.
-- ------------------------------------------

-- Step A: Record timestamp prior to update
SELECT customer_id, name, updated_at FROM Customer WHERE customer_id = 1;

-- Step B: Modify customer profile
UPDATE Customer
SET address = 'Updated Address, Dhaka'
WHERE customer_id = 1;

-- Step C: Verify `updated_at` refreshed to current timestamp
SELECT customer_id, name, updated_at FROM Customer WHERE customer_id = 1;