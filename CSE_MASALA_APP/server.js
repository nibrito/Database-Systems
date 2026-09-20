const express = require('express');
const cors = require('cors');
const sql = require('mssql');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Database Connection Configuration
const dbConfig = {
    user: 'sa',
    password: 'Admin123!', // Ensure this matches your SQL Server password
    server: 'DESKTOP-5903S8A\\SQLEXPRESS',
    database: 'CSE_MASALA_FINAL',
    options: {
        encrypt: false,
        trustServerCertificate: true
    }
};

const poolPromise = new sql.ConnectionPool(dbConfig)
    .connect()
    .then(pool => {
        console.log('✅ Connected to MSSQL: CSE_MASALA_FINAL');
        return pool;
    })
    .catch(err => console.error('❌ Database Connection Failed:', err));

// --- 1. AUTHENTICATION (Branch Manager Login) ---
app.post('/api/login', async (req, res) => {
    const { username, password } = req.body;
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('username', sql.VarChar(50), username)
            .input('password', sql.VarChar(255), password)
            .query(`
                SELECT u.user_id, u.username, e.employee_id, e.name AS employee_name, 
                       e.position, b.branch_id, b.branch_name
                FROM UserAccount u
                INNER JOIN Employee e ON u.employee_id = e.employee_id
                INNER JOIN Branch b ON e.branch_id = b.branch_id
                INNER JOIN UserRole ur ON u.user_id = ur.user_id
                INNER JOIN Role r ON ur.role_id = r.role_id
                WHERE u.username = @username 
                  AND u.password_hash = @password 
                  AND (r.role_name = 'Branch Manager' OR r.role_name = 'Admin')
            `);

        if (result.recordset.length > 0) {
            res.json({ success: true, user: result.recordset[0] });
        } else {
            res.status(401).json({ success: false, message: 'Invalid credentials or not a Branch Manager' });
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- 2. GET DISTINCT BRANCHES ---
app.get('/api/branches', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request().query(`
            SELECT MIN(branch_id) AS branch_id, branch_name 
            FROM Branch 
            GROUP BY branch_name 
            ORDER BY branch_id ASC
        `);
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- 3. GET WAITERS ONLY (Strictly Filtered by Branch) ---
app.get('/api/waiters', async (req, res) => {
    const branchId = req.query.branch_id;
    try {
        const pool = await poolPromise;
        let query = `
            SELECT employee_id, name, phone, branch_id 
            FROM Employee 
            WHERE position = 'Waiter' AND employment_status = 'Active'
        `;
        if (branchId) {
            query += ` AND branch_id = @branch_id`;
        }
        query += ` ORDER BY name ASC`;

        const request = pool.request();
        if (branchId) request.input('branch_id', sql.Int, branchId);
        
        const result = await request.query(query);
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- 4. GET UNIQUE FOOD MENU ITEMS ---
app.get('/api/food', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request().query(`
            SELECT 
                MIN(f.food_id) AS food_id,
                f.food_name,
                MAX(f.description) AS description,
                MAX(f.price) AS price,
                MAX(CAST(f.availability AS INT)) AS availability,
                MAX(c.category_name) AS category_name,
                f.category_id
            FROM Food f
            INNER JOIN Category c ON f.category_id = c.category_id
            GROUP BY f.category_id, f.food_name
            ORDER BY f.category_id ASC, f.food_name ASC
        `);
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- 5. GET INVENTORY (Deduplicated per Branch) ---
app.get('/api/inventory', async (req, res) => {
    try {
        const pool = await poolPromise;
        const branchId = req.query.branch_id || 1;
        const result = await pool.request()
            .input('branch_id', sql.Int, branchId)
            .query(`
                SELECT 
                    ing.ingredient_id,
                    ing.ingredient_name,
                    ing.unit,
                    ing.reorder_level,
                    ing.ingredient_status,
                    SUM(inv.quantity_in_stock) AS quantity_in_stock,
                    MAX(inv.last_updated) AS last_updated,
                    CASE WHEN SUM(inv.quantity_in_stock) < ing.reorder_level THEN 1 ELSE 0 END AS is_low_stock
                FROM Ingredient ing
                INNER JOIN Inventory inv ON ing.ingredient_id = inv.ingredient_id
                WHERE inv.branch_id = @branch_id
                GROUP BY 
                    ing.ingredient_id, 
                    ing.ingredient_name, 
                    ing.unit, 
                    ing.reorder_level, 
                    ing.ingredient_status
                ORDER BY is_low_stock DESC, ing.ingredient_name ASC
            `);
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- 6. RESTOCK INVENTORY ---
app.put('/api/inventory/restock', async (req, res) => {
    const { branch_id, ingredient_id, quantity_to_add } = req.body;

    const qty = parseFloat(quantity_to_add);
    if (isNaN(qty) || qty <= 0) {
        return res.status(400).json({ error: 'Please provide a valid restocking quantity greater than zero.' });
    }

    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('branch_id', sql.Int, branch_id)
            .input('ingredient_id', sql.Int, ingredient_id)
            .input('quantity_to_add', sql.Decimal(10, 2), qty)
            .query(`
                UPDATE Inventory
                SET quantity_in_stock = quantity_in_stock + @quantity_to_add
                WHERE branch_id = @branch_id AND ingredient_id = @ingredient_id;

                SELECT @@ROWCOUNT AS rows_affected;
            `);

        if (result.recordset[0].rows_affected > 0) {
            res.json({ success: true, message: 'Stock updated successfully.' });
        } else {
            await pool.request()
                .input('branch_id', sql.Int, branch_id)
                .input('ingredient_id', sql.Int, ingredient_id)
                .input('quantity_in_stock', sql.Decimal(10, 2), qty)
                .query(`
                    INSERT INTO Inventory (branch_id, ingredient_id, quantity_in_stock)
                    VALUES (@branch_id, @ingredient_id, @quantity_in_stock);
                `);
            res.json({ success: true, message: 'New inventory record initialized and restocked.' });
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- 7. GET ORDERS ---
app.get('/api/orders', async (req, res) => {
    const branchId = req.query.branch_id;
    try {
        const pool = await poolPromise;
        let query = `
            SELECT o.order_id, o.order_date, o.total_amount, o.order_status,
                   b.branch_name, b.branch_id, e.name AS server_name,
                   ISNULL(c.name, 'Walk-in Customer') AS customer_name,
                   c.phone AS customer_phone,
                   p.payment_status, p.payment_method
            FROM Orders o
            INNER JOIN Branch b ON o.branch_id = b.branch_id
            INNER JOIN Employee e ON o.employee_id = e.employee_id
            LEFT JOIN Customer c ON o.customer_id = c.customer_id
            LEFT JOIN Payment p ON o.order_id = p.order_id
        `;
        if (branchId) {
            query += ` WHERE o.branch_id = @branch_id`;
        }
        query += ` ORDER BY o.order_id DESC`;

        const request = pool.request();
        if (branchId) request.input('branch_id', sql.Int, branchId);
        
        const result = await request.query(query);
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- 8. POST NEW ORDER (With Ingredient Stock Pre-Check) ---
app.post('/api/orders', async (req, res) => {
    const { branch_id, employee_id, customer, payment_method, items } = req.body;
    
    if (!items || items.length === 0) {
        return res.status(400).json({ error: 'Order must contain items' });
    }

    const pool = await poolPromise;
    const transaction = new sql.Transaction(pool);

    try {
        await transaction.begin();

        // Check if any ingredient is out of stock in this branch
        for (const item of items) {
            const stockCheckReq = new sql.Request(transaction);
            const stockCheck = await stockCheckReq
                .input('branch_id', sql.Int, branch_id)
                .input('food_id', sql.Int, item.food_id)
                .input('ordered_qty', sql.Int, item.quantity)
                .query(`
                    SELECT 
                        f.food_name,
                        ing.ingredient_name,
                        (fi.quantity_required * @ordered_qty) AS required_amount,
                        ISNULL(inv.quantity_in_stock, 0) AS current_stock
                    FROM Food_Ingredient fi
                    INNER JOIN Food f ON fi.food_id = f.food_id
                    INNER JOIN Ingredient ing ON fi.ingredient_id = ing.ingredient_id
                    LEFT JOIN Inventory inv ON inv.ingredient_id = fi.ingredient_id AND inv.branch_id = @branch_id
                    WHERE fi.food_id = @food_id 
                      AND ISNULL(inv.quantity_in_stock, 0) < (fi.quantity_required * @ordered_qty)
                `);

            if (stockCheck.recordset.length > 0) {
                const missing = stockCheck.recordset[0];
                await transaction.rollback();
                return res.status(400).json({
                    error: `Cannot place order for "${missing.food_name}". Insufficient "${missing.ingredient_name}" in this branch (Required: ${missing.required_amount}, In Stock: ${missing.current_stock}).`
                });
            }
        }

        // Customer insertion
        let customerId = null;
        if (customer && customer.name) {
            const custReq = new sql.Request(transaction);
            const custResult = await custReq
                .input('name', sql.VarChar(100), customer.name)
                .input('phone', sql.VarChar(20), customer.phone || null)
                .input('address', sql.VarChar(100), customer.address || null)
                .query(`
                    INSERT INTO Customer (name, phone, address)
                    OUTPUT INSERTED.customer_id
                    VALUES (@name, @phone, @address)
                `);
            customerId = custResult.recordset[0].customer_id;
        }

        // Order insertion
        const orderReq = new sql.Request(transaction);
        const orderResult = await orderReq
            .input('customer_id', sql.Int, customerId)
            .input('branch_id', sql.Int, branch_id)
            .input('employee_id', sql.Int, employee_id)
            .query(`
                INSERT INTO Orders (customer_id, branch_id, employee_id, order_status)
                OUTPUT INSERTED.order_id
                VALUES (@customer_id, @branch_id, @employee_id, 'completed')
            `);
        const orderId = orderResult.recordset[0].order_id;

        // Items insertion
        let calculatedTotal = 0;
        for (const item of items) {
            const itemReq = new sql.Request(transaction);
            await itemReq
                .input('order_id', sql.Int, orderId)
                .input('food_id', sql.Int, item.food_id)
                .input('quantity', sql.Int, item.quantity)
                .input('unit_price', sql.Decimal(10, 2), item.unit_price)
                .query(`
                    INSERT INTO OrderItem (order_id, food_id, quantity, unit_price)
                    VALUES (@order_id, @food_id, @quantity, @unit_price)
                `);
            calculatedTotal += (item.quantity * item.unit_price);
        }

        // Payment record
        const payReq = new sql.Request(transaction);
        await payReq
            .input('order_id', sql.Int, orderId)
            .input('amount', sql.Decimal(10, 2), calculatedTotal)
            .input('payment_method', sql.VarChar(30), payment_method || 'Cash')
            .query(`
                INSERT INTO Payment (order_id, amount, payment_method, payment_status)
                VALUES (@order_id, @amount, @payment_method, 'paid')
            `);

        await transaction.commit();
        res.status(201).json({ success: true, order_id: orderId, total: calculatedTotal });
    } catch (err) {
        await transaction.rollback();
        res.status(500).json({ error: err.message });
    }
});

// --- 9. CANCEL ORDER (Triggers Orders_RestockOnCancel) ---
app.put('/api/orders/:id/cancel', async (req, res) => {
    const orderId = req.params.id;
    try {
        const pool = await poolPromise;
        const result = await pool.request()
            .input('order_id', sql.Int, orderId)
            .query(`
                UPDATE Orders 
                SET order_status = 'cancelled' 
                WHERE order_id = @order_id AND order_status <> 'cancelled';

                UPDATE Payment
                SET payment_status = 'cancelled'
                WHERE order_id = @order_id;
            `);

        if (result.rowsAffected[0] > 0) {
            res.json({ success: true, message: `Order #${orderId} cancelled and stock returned to inventory.` });
        } else {
            res.status(400).json({ success: false, message: 'Order is already cancelled or does not exist.' });
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- 10. GET ANALYTICS ---
app.get('/api/analytics', async (req, res) => {
    const branchId = req.query.branch_id;
    try {
        const pool = await poolPromise;
        let query = `
            SELECT 
                (SELECT COUNT(*) FROM Orders ${branchId ? 'WHERE branch_id = @branch_id' : ''}) AS total_orders,
                (SELECT ISNULL(SUM(total_amount), 0) FROM Orders WHERE order_status != 'cancelled' ${branchId ? 'AND branch_id = @branch_id' : ''}) AS branch_revenue,
                (SELECT COUNT(*) FROM Employee WHERE employment_status = 'Active' ${branchId ? 'AND branch_id = @branch_id' : ''}) AS active_employees,
                (SELECT COUNT(DISTINCT inv.ingredient_id) FROM Inventory inv 
                 INNER JOIN Ingredient ing ON inv.ingredient_id = ing.ingredient_id 
                 WHERE inv.quantity_in_stock < ing.reorder_level ${branchId ? 'AND inv.branch_id = @branch_id' : ''}) AS low_stock_alerts
        `;

        const request = pool.request();
        if (branchId) request.input('branch_id', sql.Int, branchId);

        const result = await request.query(query);
        res.json(result.recordset[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- 11. GET EMPLOYEES ---
app.get('/api/employees', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request().query(`
            SELECT e.employee_id, e.name, e.phone, e.email, e.position, 
                   e.salary, e.employment_status, b.branch_name, b.branch_id
            FROM Employee e
            INNER JOIN Branch b ON e.branch_id = b.branch_id
            ORDER BY e.employee_id ASC
        `);
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

const PORT = 3000;
app.listen(PORT, () => console.log(`🚀 Server listening on http://localhost:${PORT}`));